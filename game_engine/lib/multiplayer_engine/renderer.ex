defmodule MultiplayerEngine.Renderer do
  def start, do: Agent.update(__MODULE__, fn state -> %{state | enabled: true} end)
  def stop, do: Agent.update(__MODULE__, fn state -> %{state | enabled: false} end)
  def active?, do: Agent.get(__MODULE__, fn state -> state.enabled end)

  def focus_zone(zone) do
    Agent.update(__MODULE__, fn state -> %{state | focus: zone} end)
    render_zone(zone)
  end

  def current_focus, do: Agent.get(__MODULE__, fn state -> state.focus end)

  def render_zone(zone_id) do
    zone_id |> MultiplayerEngine.ZoneServer.get_players() |> render()
  end

  def render(players) do
    if active?() do
      IO.write("\e[2J\e[H")

      players
      |> Enum.sort_by(fn {_, %{x: x, y: y}} -> {y, x} end)
      |> Enum.each(fn {player_id, %{x: x, y: y}} ->
        safe_x = max(1, min(x, 78))
        safe_y = max(1, min(y, 20))
        IO.write("\e[#{safe_y};#{safe_x}H[#{player_id}] ")
      end)

      IO.write("\e[21;1HPlayers online: #{map_size(players)}\n")
      IO.write("\e[22;1HZone: #{current_focus()}\n")
    end
  end
end
