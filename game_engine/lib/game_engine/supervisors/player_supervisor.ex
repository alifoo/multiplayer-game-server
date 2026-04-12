defmodule GameEngine.PlayerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_player(player_id) do
    child_spec = %{
      id: GameEngine.PlayerConnection,
      start: {GameEngine.PlayerConnection, :start_link, [player_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
