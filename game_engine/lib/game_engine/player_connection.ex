defmodule GameEngine.PlayerConnection do
  use GenServer

  def start_link(player_id) do
    name = {:via, Registry, {GameEngine.Registry, player_id}}
    GenServer.start_link(__MODULE__, player_id, name: name)
  end

  @impl true
  def init(player_id) do
    IO.puts("Starting PlayerConnection for player #{player_id}")
    {:ok, %{player_id: player_id}}
  end
end
