defmodule GameEngine.Renderer do
  def render(players) do
    # Clear terminal
    IO.write("\e[2J\e[H")

    Enum.each(players, fn {player_id, %{x: x, y: y}} ->
      safe_x = max(1, x)
      safe_y = max(1, y)
      IO.write("\e[#{safe_y};#{safe_x}H#{player_id}")
    end)

    # Print the UI text on a line far below the "game board", like line 20
    IO.write("\e[21;1HPlayers online: #{map_size(players)}\n")
  end
end
