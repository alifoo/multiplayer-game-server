defmodule GameEngine.Matchmaker do
  use GenServer

  @party_size 3

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def join_queue(player_id) do
    GenServer.call(__MODULE__, {:join_queue, player_id})
  end

  def get_queue do
    GenServer.call(__MODULE__, :get_queue)
  end

  @impl true
  def init(:ok) do
    {:ok, %{queue: []}}
  end

  @impl true
  def handle_call({:join_queue, player_id}, _from, state) do
    queue = state.queue ++ [player_id]

    if length(queue) >= @party_size do
      {party, remaining} = Enum.split(queue, @party_size)
      dungeon_id = :"dungeon_#{:erlang.unique_integer([:positive])}"

      spawn_dungeon(dungeon_id, party)

      {:reply, {:matched, dungeon_id, party}, %{state | queue: remaining}}
    else
      {:reply, {:queued, length(queue), @party_size}, %{state | queue: queue}}
    end
  end

  @impl true
  def handle_call(:get_queue, _from, state) do
    {:reply, state.queue, state}
  end

  defp spawn_dungeon(dungeon_id, party) do
    GameEngine.DungeonSupervisor.create_dungeon(dungeon_id)

    Enum.each(party, fn player_id ->
      player_state = GameEngine.Player.get_state(player_id)
      [{pid, _}] = Registry.lookup(GameEngine.Registry, {:player, player_id})

      GameEngine.ZoneServer.remove_player(player_state.zone, player_id)
      GameEngine.DungeonServer.add_player(dungeon_id, player_id, pid, player_state.x, player_state.y, player_state.zone)
    end)

    IO.puts("[MATCHMAKER] Dungeon #{dungeon_id} created with party: #{inspect(party)}")
  end
end
