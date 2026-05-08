defmodule GridEx.Topology do
  alias GridEx.Node
  alias GridEx.Edge

  @type t :: %__MODULE__{
          nodes: %{integer() => Node.t()},
          edges: %{integer() => Edge.t()}
        }

  defstruct nodes: %{}, edges: %{}
end
