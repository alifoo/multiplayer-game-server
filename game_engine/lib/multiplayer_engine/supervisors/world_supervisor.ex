defmodule MultiplayerEngine.WorldSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_zone(world_id) do
    child_spec = %{
      id: MultiplayerEngine.ZoneServer,
      start: {MultiplayerEngine.ZoneServer, :start_link, [world_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
