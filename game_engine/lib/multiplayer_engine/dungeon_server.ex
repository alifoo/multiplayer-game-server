defmodule MultiplayerEngine.DungeonServer do
  use GenServer

  def start_link(dungeon_id) do
    name = via(dungeon_id)
    GenServer.start_link(__MODULE__, dungeon_id, name: name)
  end

  def add_player(dungeon_id, player_id, player_pid, start_x, start_y, origin_zone) do
    GenServer.cast(
      via(dungeon_id),
      {:add_player, player_id, player_pid, start_x, start_y, origin_zone}
    )
  end

  def remove_player(dungeon_id, player_id) do
    GenServer.cast(via(dungeon_id), {:remove_player, player_id})
  end

  def update_player_position(dungeon_id, player_id, x, y) do
    GenServer.cast(via(dungeon_id), {:update_position, player_id, x, y})
  end

  def get_players(dungeon_id) do
    GenServer.call(via(dungeon_id), :get_players)
  end

  def crash_dungeon(dungeon_id) do
    GenServer.cast(via(dungeon_id), :simulate_crash)
  end

  @impl true
  def init(dungeon_id) do
    check_restart_tracker(dungeon_id)
    players = restore_players(dungeon_id)
    {:ok, %{dungeon_id: dungeon_id, players: players, state: :active}}
  end

  @impl true
  def handle_cast(:simulate_crash, state) do
    raise "Simulated crash in dungeon #{state.dungeon_id}"
  end

  @impl true
  def handle_cast({:add_player, player_id, player_pid, x, y, origin_zone}, state) do
    Process.monitor(player_pid)

    players =
      Map.put(state.players, player_id, %{x: x, y: y, pid: player_pid, origin_zone: origin_zone})

    backup_state(state.dungeon_id, players)
    track_player_location(state.dungeon_id, player_id, x, y, origin_zone)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_cast({:remove_player, player_id}, state) do
    players = Map.delete(state.players, player_id)
    backup_state(state.dungeon_id, players)
    {:noreply, %{state | players: players}}
  end

  @impl true
  def handle_cast({:update_position, player_id, x, y}, state) do
    players = Map.update!(state.players, player_id, fn p -> %{p | x: x, y: y} end)
    backup_state(state.dungeon_id, players)
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

  defp via(dungeon_id) do
    {:via, Registry, {MultiplayerEngine.Registry, {:DungeonServer, dungeon_id}}}
  end

  defp backup_state(dungeon_id, players) do
    :ets.insert(:dungeon_state, {dungeon_id, players})
  end

  defp track_player_location(dungeon_id, player_id, x, y, origin_zone) do
    :ets.insert(:player_location_tracker, {player_id, dungeon_id, x, y, origin_zone})
  end

  defp check_restart_tracker(dungeon_id) do
    case :ets.lookup(:restart_tracker, dungeon_id) do
      [{^dungeon_id, killed_at}] ->
        restart_time_us = :erlang.monotonic_time(:microsecond) - killed_at
        IO.puts("[RESTARTED] DungeonServer #{dungeon_id}: recovered in #{restart_time_us} µs")
        :ets.delete(:restart_tracker, dungeon_id)

      [] ->
        :ok
    end
  end

  defp restore_players(dungeon_id) do
    case :ets.lookup(:dungeon_state, dungeon_id) do
      [{^dungeon_id, saved_players}] ->
        saved_players

      [] ->
        IO.puts("No saved state for dungeon id: #{dungeon_id}, starting fresh")
        %{}
    end
  end
end
