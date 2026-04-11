defmodule GameEngine.PlayerConnection do
  use GenServer

  def start_link(player_id) do
    name = {:via, Registry, {GameEngine.Registry, {:player, player_id}}}
    GenServer.start_link(__MODULE__, player_id, name: name)
  end

  def move(player_id, x, y) do
    GenServer.cast(via(player_id), {:move, x, y})
  end

  def get_state(player_id) do
    GenServer.call(via(player_id), :get_state)
  end

  @impl true
  def init(player_id) do
    IO.puts("Starting PlayerConnection for player #{player_id}")
    state = %{player_id: player_id, x: 0, y: 0, zone: :zone_1}
    GameEngine.ZoneServer.add_player(state.zone, player_id)
    {:ok, state}
  end

  @impl true
  def handle_cast({:move, x, y}, state) do
    new_state = %{state | x: x, y: y}
    GameEngine.ZoneServer.update_player_position(state.zone, state.player_id, x, y)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def terminate(_reason, state) do
    IO.puts("Player connection for player #{state.player_id} is terminating")
    GameEngine.ZoneServer.remove_player(state.zone, state.player_id)
  end

  defp via(player_id) do
    {:via, Registry, {GameEngine.Registry, {:player, player_id}}}
  end
end
