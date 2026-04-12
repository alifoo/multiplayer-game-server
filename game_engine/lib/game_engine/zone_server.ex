defmodule GameEngine.ZoneServer do
  use GenServer

  def start_link(zone_id) do
    name = via(zone_id)
    GenServer.start_link(__MODULE__, zone_id, name: name)
  end

  def add_player(zone, player_id, player_pid, start_x, start_y) do
    GenServer.cast(via(zone), {:add_player, player_id, player_pid, start_x, start_y})
  end

  def remove_player(zone, player_id) do
    GenServer.cast(via(zone), {:remove_player, player_id})
  end

  def update_player_position(zone, player_id, x, y) do
    GenServer.cast(via(zone), {:update_position, player_id, x, y})
  end

  def get_players(zone) do
    GenServer.call(via(zone), :get_players)
  end

  def crash_zone(zone) do
    GenServer.cast(via(zone), :simulate_crash)
  end

  @impl true
  def init(zone_id) do
    :timer.send_interval(1000, self(), :tick)

    players =
      case :ets.lookup(:zone_state, zone_id) do
        [{^zone_id, saved_players}] ->
          IO.puts("Restoring state for zone #{zone_id} with #{map_size(saved_players)} players")
          saved_players

        [] ->
          IO.puts("No saved state for zone #{zone_id}, starting fresh")
          %{}
      end

    {:ok, %{zone_id: zone_id, players: players, state: :active}}
  end

  @impl true
  def handle_cast(:simulate_crash, state) do
    raise "Simulated crash in zone #{state.zone_id}"
  end

  @impl true
  def handle_cast({:add_player, player_id, player_pid, x, y}, state) do
    Process.monitor(player_pid)
    players = Map.put(state.players, player_id, %{x: x, y: y, pid: player_pid})

    backup_state(state.zone_id, players)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_cast({:remove_player, player_id}, state) do
    players = Map.delete(state.players, player_id)
    backup_state(state.zone_id, players)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_cast({:update_position, player_id, x, y}, state) do
    players = Map.update!(state.players, player_id, fn p -> %{p | x: x, y: y} end)
    backup_state(state.zone_id, players)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_call(:get_players, _from, state) do
    {:reply, state.players, state}
  end

  @impl true
  def handle_info(:tick, state) do
    if GameEngine.Renderer.current_focus() == state.zone_id do
      GameEngine.Renderer.render(state.players)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, dead_pid, reason}, state) do
    IO.puts("Player process #{inspect(dead_pid)} has terminated with reason: #{inspect(reason)}")
    {player_id, _} = Enum.find(state.players, fn {_, data} -> data.pid == dead_pid end)
    players = Map.delete(state.players, player_id)

    {:noreply, %{state | players: players}}
  end

  defp via(zone_id) do
    {:via, Registry, {GameEngine.Registry, {:ZoneServer, zone_id}}}
  end

  defp backup_state(zone_id, players) do
    :ets.insert(:zone_state, {zone_id, players})
  end
end
