defmodule GridEx.Node do
  @type t :: %__MODULE__{
          # metadata
          id: integer(),
          name: String.t(),
          bus_type: :slack | :pv | :pq,
          # power flow params
          # type
          type: :generator | :load | :storage | :bus,
          # power in MW
          # a generator injects power, so (+), a load consumes, so (-)
          p_mw: float(),
          # voltage in power unit
          v_pu: float(),
          # angle 
          theta: float(),
          schedule: GridEx.Schedule.t() | nil
        }

  defstruct id: nil,
            name: nil,
            bus_type: nil,
            type: nil,
            p_mw: nil,
            v_pu: nil,
            theta: nil,
            schedule: nil
end
