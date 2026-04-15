defmodule MultiplayerEngine.DungeonSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 1000, max_seconds: 5)
  end

  def create_dungeon(dungeon_id) do
    child_spec = %{
      id: MultiplayerEngine.DungeonServer,
      start: {MultiplayerEngine.DungeonServer, :start_link, [dungeon_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
