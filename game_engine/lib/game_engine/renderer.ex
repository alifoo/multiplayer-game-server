defmodule GameEngine.Renderer do
  def focus_zone(zone), do: Agent.update(__MODULE__, fn _ -> zone end)
  def current_focus(), do: Agent.get(__MODULE__, fn state -> state end)

  def render_zone(zone_id) do
    focus_zone(zone_id)
    zone_id |> GameEngine.ZoneServer.get_players() |> render()
  end

  def render(players) do
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
