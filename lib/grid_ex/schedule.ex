defmodule GridEx.Schedule do
  @type t ::
          {:constant, float()}
          | {:sinusoidal,
             %{
               amplitude: float(),
               period_ticks: float(),
               phase_rad: float(),
               offset_mw: float()
             }}
          | {:piecewise, [{integer(), float()}]}

  def at(nil, _tick), do: 0.0
  def at({:constant, p}, _tick), do: p

  def at({:sinusoidal, params}, tick) do
    params.offset_mw +
      params.amplitude *
        :math.sin(2 * :math.pi() * (tick / params.period_ticks) + params.phase_rad)
  end

  def at({:piecewise, parts}, tick) do
    {_part_tick, value} =
      Enum.filter(parts, fn {part_tick, _value} -> part_tick <= tick end)
      |> List.last({nil, 0.0})

    # Enum.find(parts, 0, fn {part_tick, _value} -> part_tick <= tick end)

    value
  end
end
