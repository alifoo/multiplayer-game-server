defmodule GameEngine.DungeonSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_dungeon(dungeon_id) do
    child_spec = %{
      id: GameEngine.DungeonServer,
      start: {GameEngine.DungeonServer, :start_link, [dungeon_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
