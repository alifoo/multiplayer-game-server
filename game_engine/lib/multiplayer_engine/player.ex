defmodule MultiplayerEngine.Player do
  use GenServer

  def start_link(player_id, zone_id) do
    name = via(player_id)
    GenServer.start_link(__MODULE__, {player_id, zone_id}, name: name)
  end

  def move(player_id, x, y) do
    GenServer.cast(via(player_id), {:move, x, y})
  end

  def get_state(player_id) do
    GenServer.call(via(player_id), :get_state)
  end

  def simulate_crash(player_id) do
    GenServer.cast(via(player_id), :simulate_crash)
  end

  @impl true
  def init({player_id, zone_id}) do
    check_restart_tracker(player_id, zone_id)

    start_x = Enum.random(1..150)
    start_y = Enum.random(1..150)

    resolve_location(player_id, zone_id, start_x, start_y)
  end

  @impl true
  def handle_cast({:move, x, y}, state) do
    new_state = %{state | x: x, y: y}
    MultiplayerEngine.ZoneServer.update_player_position(state.zone, state.player_id, x, y)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:simulate_crash, state) do
    raise "Simulated crash for player #{state.player_id}"
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def terminate(_reason, state) do
    IO.puts("[TERMINATED] Player #{state.player_id} is terminating")
    MultiplayerEngine.ZoneServer.remove_player(state.zone, state.player_id)
  end

  defp via(player_id) do
    {:via, Registry, {MultiplayerEngine.Registry, {:player, player_id}}}
  end

  defp check_restart_tracker(player_id, zone_id) do
    case :ets.lookup(:restart_tracker, player_id) do
      [{^player_id, killed_at}] ->
        restart_time_us = :erlang.monotonic_time(:microsecond) - killed_at

        IO.puts(
          "[RESTARTED] Player #{player_id} in zone #{zone_id}: recovered in #{restart_time_us} µs"
        )

        :ets.delete(:restart_tracker, player_id)

      [] ->
        IO.puts("[STARTED] Player #{player_id} in zone #{zone_id}")
    end
  end

  defp resolve_location(player_id, zone_id, x, y) do
    case :ets.lookup(:player_location_tracker, player_id) do
      [{^player_id, dungeon_id, _x, _y, origin_zone}] ->
        IO.puts("[RECOVERED] Player #{player_id} rejoining dungeon #{dungeon_id}")

        MultiplayerEngine.DungeonServer.add_player(
          dungeon_id,
          player_id,
          self(),
          x,
          y,
          origin_zone
        )

        :ets.delete(:player_location_tracker, player_id)
        {:ok, %{player_id: player_id, x: x, y: y, zone: origin_zone}}

      [] ->
        MultiplayerEngine.ZoneServer.add_player(zone_id, player_id, self(), x, y)
        {:ok, %{player_id: player_id, x: x, y: y, zone: zone_id}}
    end
  end
end
