defmodule MultiplayerEngine.ZoneServer do
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
    check_restart_tracker(zone_id)
    players = restore_players(zone_id)
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
  def handle_info({:DOWN, _ref, :process, dead_pid, reason}, state) do
    case Enum.find(state.players, fn {_, data} -> data.pid == dead_pid end) do
      {player_id, _} ->
        IO.puts("Player id #{player_id} process has terminated with reason: #{inspect(reason)}")
        players = Map.delete(state.players, player_id)
        {:noreply, %{state | players: players}}

      nil ->
        {:noreply, state}
    end
  end

  defp via(zone_id) do
    {:via, Registry, {MultiplayerEngine.Registry, {:ZoneServer, zone_id}}}
  end

  defp backup_state(zone_id, players) do
    :ets.insert(:zone_state, {zone_id, players})
  end

  defp check_restart_tracker(zone_id) do
    case :ets.lookup(:restart_tracker, zone_id) do
      [{^zone_id, killed_at}] ->
        restart_time_us = :erlang.monotonic_time(:microsecond) - killed_at
        IO.puts("[RESTARTED] ZoneServer #{zone_id}: recovered in #{restart_time_us} µs")
        :ets.delete(:restart_tracker, zone_id)

      [] ->
        :ok
    end
  end

  defp restore_players(zone_id) do
    case :ets.lookup(:zone_state, zone_id) do
      [{^zone_id, saved_players}] ->
        saved_players

      [] ->
        IO.puts("No saved state for zone id: #{zone_id}, starting fresh")
        %{}
    end
  end
end
