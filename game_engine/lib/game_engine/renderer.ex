defmodule GameEngine.Renderer do
  def render(players) do
    # Clear terminal
    IO.write("\e[2J\e[H")

    Enum.each(players, fn {_, %{x: x, y: y}} ->
      # Ensure minimum 1;1 coordinate, otherwise the terminal might ignore it
      safe_x = max(1, x)
      safe_y = max(1, y)
      IO.write("\e[#{safe_y};#{safe_x}H@")
    end)

    # Print the UI text on a line far below the "game board", like line 20
    IO.write("\e[20;1HPlayers online: #{map_size(players)}\n")
  end
end
