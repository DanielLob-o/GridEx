defmodule GridEx.SimulationServer do
  use GenServer
  alias GridEx.Schedule
  alias GridEx.PowerFlow.Dc

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)

    GenServer.start_link(__MODULE__, opts,
      name: {:via, Registry, {GridEx.SimulationRegistry, id}}
    )
  end

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    base_topology = Keyword.fetch!(opts, :base_topology)
    topology = Keyword.fetch!(opts, :topology)
    tick = Keyword.fetch!(opts, :tick)
    status = Keyword.get(opts, :status, nil)
    interval_ms = Keyword.get(opts, :interval_ms, 1000)

    state = %{
      id: id,
      # default topology (static)
      base_topology: base_topology,
      # current topology (dynamic)
      topology: topology,
      # current tick 
      tick: tick,
      # topology status 
      status: status,
      # how much between ticks 
      interval_ms: interval_ms
    }

    Process.send_after(self(), :internal_tick, state.interval_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(:internal_tick, state) do
    # apply_schedules
    # solve
    # broadcast
    # reeschedule self 
    # return no reply and new state
    new_state =
      state
      |> apply_schedules()
      |> solve()
      |> broadcast()

    Process.send_after(self(), :internal_tick, new_state.interval_ms)
    {:noreply, new_state}
  end

  @spec apply_schedules(map()) :: map()
  defp apply_schedules(%{topology: topology, tick: tick} = state) do
    updated_nodes =
      topology.nodes
      |> Map.new(fn {id, node} ->
        updated_node =
          if node.schedule, do: %{node | p_mw: Schedule.at(node.schedule, tick)}, else: node

        {id, updated_node}
      end)

    updated_topology = %{topology | nodes: updated_nodes}
    %{state | topology: updated_topology}
  end

  defp solve(state) do
    new_topology = Dc.do_calculate(state.topology)

    %{state | topology: new_topology, tick: state.tick + 1}
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(
      GridEx.PubSub,
      "simulation:#{state.id}",
      {:tick_result, state.tick, state.topology}
    )

    state
  end
end
