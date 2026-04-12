defmodule GameEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:zone_state, [:set, :public, :named_table])
    :ets.new(:restart_tracker, [:set, :public, :named_table])
    :ets.new(:dungeon_state, [:set, :public, :named_table])
    :ets.new(:player_location_tracker, [:set, :public, :named_table])

    children = [
      # Starts a worker by calling: GameEngine.Worker.start_link(arg)
      # {GameEngine.Worker, arg}
      {Registry, keys: :unique, name: GameEngine.Registry},
      %{
        id: :renderer_focus,
        start:
          {Agent, :start_link,
           [fn -> %{focus: :zone_1, enabled: false} end, [name: GameEngine.Renderer]]}
      },
      GameEngine.WorldSupervisor,
      GameEngine.PlayerSupervisor,
      GameEngine.DungeonSupervisor,
      GameEngine.Matchmaker,
      %{
        id: :zone_bootstrapper,
        start: {Task, :start_link, [fn -> boot_initial_zones() end]},
        restart: :temporary
      }
    ]

    opts = [strategy: :one_for_one, name: GameEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp boot_initial_zones do
    IO.puts("Bootstrapping initial zones...")

    world_map = %{
      :zone_1 => %{name: "Green Fields", description: "A peaceful grassy area."},
      :zone_2 => %{name: "Dark Forest", description: "A spooky, dense forest."},
      :zone_3 => %{name: "Crystal Caves", description: "Shiny caves filled with crystals."},
      :zone_4 => %{name: "Volcanic Wasteland", description: "A harsh, fiery landscape."},
      :zone_5 => %{name: "Sky Islands", description: "Floating islands in the sky."}
    }

    Enum.each(world_map, fn {zone_id, _info} ->
      GameEngine.WorldSupervisor.start_zone(zone_id)
    end)
  end
end
