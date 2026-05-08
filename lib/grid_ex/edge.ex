defmodule GridEx.Edge do
  @type t :: %__MODULE__{
          # metadata
          id: integer(),
          name: String.t(),
          # power flow params
          # resistance: float(), resistance in the model we're using is always 0 
          # reactance in power unit
          # X; Susceptance = 1/X
          reactance_pu: float(),
          # capacity in MW
          capacity_mw: float(),
          from: integer(),
          to: integer(),
          # flow sign convention a generator injects power, so (+), a load consumes, so (-)
          flow_mw: float()
        }

  defstruct id: nil,
            name: nil,
            reactance_pu: nil,
            capacity_mw: nil,
            from: nil,
            to: nil,
            flow_mw: nil
end
