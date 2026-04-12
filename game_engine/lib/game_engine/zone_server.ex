defmodule GameEngine.ZoneServer do
  use GenServer

  def start_link(zone_id) do
    name = via(zone_id)
    GenServer.start_link(__MODULE__, zone_id, name: name)
  end

  def add_player(zone, player_id, start_x, start_y) do
    GenServer.cast(via(zone), {:add_player, player_id, start_x, start_y})
  end

  def remove_player(zone, player_id) do
    GenServer.cast(via(zone), {:remove_player, player_id})
  end

  def update_player_position(zone, player_id, x, y) do
    GenServer.cast(via(zone), {:update_position, player_id, x, y})
  end

  @impl true
  def init(zone_id) do
    :timer.send_interval(100, self(), :tick)
    {:ok, %{zone_id: zone_id, players: %{}, state: :active}}
  end

  @impl true
  def handle_cast({:add_player, player_id, x, y}, state) do
    players = Map.put(state.players, player_id, %{x: x, y: y})
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_cast({:remove_player, player_id}, state) do
    players = Map.delete(state.players, player_id)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_cast({:update_position, player_id, x, y}, state) do
    players = Map.update!(state.players, player_id, fn p -> %{p | x: x, y: y} end)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_info(:tick, state) do
    GameEngine.Renderer.render(state.players)
    {:noreply, state}
  end

  defp via(zone_id) do
    {:via, Registry, {GameEngine.Registry, {:ZoneServer, zone_id}}}
  end
end
