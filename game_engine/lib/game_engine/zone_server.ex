defmodule GameEngine.ZoneServer do
  use GenServer

  def start_link(zone_id) do
    name = {:via, Registry, {GameEngine.Registry, zone_id}}
    GenServer.start_link(__MODULE__, zone_id, name: name)
  end

  @impl true
  def init(zone_id) do
    IO.puts("Starting ZoneServer for zone #{zone_id}")
    {:ok, %{zone_id: zone_id, players: [], status: :waiting}}
  end
end
