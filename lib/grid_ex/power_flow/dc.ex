defmodule GridEx.PowerFlow.Dc do
  @moduledoc """
   thefull pipeline is:

     Build B matrix  (n×n, from all edges)
     Build P vector  (n, from all nodes)
     Reduce → B_red, P_red  (drop slack row/col)
     Solve  B_red × θ_red = P_red
     calc flows  P_ij = b_ij × (θ_i − θ_j)
  """
  alias GridEx.Topology
  alias Nx
  @spec do_calculate(Topology.t()) :: Topology.t()
  def do_calculate(topology) do
    topology
    |> build_context()
    |> build_b_matrix()
    |> build_p_tensor()
    |> reduce()
    |> solve()
    |> calc_flows()
    |> apply_results()
  end

  defp build_context(topology) do
    %{topology: topology, n: map_size(topology.nodes)}
  end

  defp build_b_matrix(%{topology: topology, n: n} = ctx) do
    initial_matrix = Nx.broadcast(0.0, {n, n})

    b_matrix =
      Enum.reduce(topology.edges, initial_matrix, fn {_id, edge}, b_acc ->
        b_ij = 1.0 / edge.reactance_pu
        indices = Nx.tensor([[edge.from, edge.to], [edge.to, edge.from]])
        indices_diagonal = Nx.tensor([[edge.from, edge.from], [edge.to, edge.to]])
        values_diagonal = Nx.tensor([b_ij, b_ij])
        values = Nx.tensor([-b_ij, -b_ij])

        b_acc
        |> Nx.indexed_put(indices, values)
        |> Nx.indexed_add(indices_diagonal, values_diagonal)
      end)

    Map.put(ctx, :b_matrix, b_matrix)
  end

  defp build_p_tensor(%{topology: topology} = ctx) do
    p_tensor =
      topology.nodes
      |> Enum.sort_by(fn {id, _node} -> id end)
      |> Enum.map(fn {_id, node} -> node.p_mw end)
      |> Nx.tensor()

    Map.put(ctx, :p_tensor, p_tensor)
  end

  defp reduce(%{n: n, b_matrix: b, p_tensor: p} = ctx) do
    b_red = Nx.slice(b, [1, 1], [n - 1, n - 1])
    p_red = Nx.slice(p, [1], [n - 1])

    ctx
    |> Map.put(:b_red, b_red)
    |> Map.put(:p_red, p_red)
  end

  defp solve(%{b_red: b, p_red: p} = ctx) do
    theta_red = Nx.LinAlg.solve(b, p)

    slack = Nx.tensor([0.0])
    theta = Nx.concatenate([slack, theta_red])

    Map.put(ctx, :theta, theta)
  end

  defp calc_flows(%{topology: topology, theta: theta} = ctx) do
    initial_map = %{}

    flows_map =
      topology.edges
      |> Enum.reduce(initial_map, fn {id, edge}, flow_acc ->
        b_ij = 1.0 / edge.reactance_pu

        p_ij =
          Nx.multiply(b_ij, Nx.subtract(theta[edge.from], theta[edge.to]))
          |> Nx.to_number()

        Map.put(flow_acc, id, p_ij)
      end)

    Map.put(ctx, :flows, flows_map)
  end

  defp apply_results(%{topology: topology, theta: theta, flows: flows} = _ctx) do
    updated_nodes =
      Map.new(topology.nodes, fn {id, node} ->
        {id, %{node | theta: Nx.to_number(theta[id])}}
      end)

    updated_edges =
      Map.new(topology.edges, fn {id, edge} ->
        {id, %{edge | flow_mw: flows[id]}}
      end)

    %{topology | nodes: updated_nodes, edges: updated_edges}
  end
end
