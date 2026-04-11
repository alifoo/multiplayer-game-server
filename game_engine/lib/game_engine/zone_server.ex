defmodule GameEngine.ZoneServer do
  use GenServer

  def start_link(zone_id) do
    name = {:via, Registry, {GameEngine.Registry, zone_id}}
    GenServer.start_link(__MODULE__, zone_id, name: name)
  end

  def add_player(zone, player_id) do
    GenServer.cast(via(zone), {:add_player, player_id})
  end

  def remove_player(zone, player_id) do
    GenServer.cast(via(zone), {:remove_player, player_id})
  end

  def update_player_position(zone, player_id, x, y) do
    GenServer.cast(via(zone), {:update_position, player_id, x, y})
  end

  @impl true
  def init(zone_id) do
    IO.puts("Starting ZoneServer for zone #{zone_id}")
    {:ok, %{zone_id: zone_id, players: [], status: :waiting}}
  end

  defp via(zone_id) do
    {:via, Registry, {GameEngine.Registry, {:ZoneServer, zone_id}}}
  end
end
