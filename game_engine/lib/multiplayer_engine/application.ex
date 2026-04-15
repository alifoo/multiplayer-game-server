defmodule MultiplayerEngine.Application do
  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:zone_state, [:set, :public, :named_table])
    :ets.new(:restart_tracker, [:set, :public, :named_table])
    :ets.new(:dungeon_state, [:set, :public, :named_table])
    :ets.new(:player_location_tracker, [:set, :public, :named_table])

    children = [
      {Registry, keys: :unique, name: MultiplayerEngine.Registry},
      MultiplayerEngine.WorldSupervisor,
      MultiplayerEngine.PlayerSupervisor,
      MultiplayerEngine.DungeonSupervisor,
      MultiplayerEngine.Matchmaker,
      %{
        id: :zone_bootstrapper,
        start: {Task, :start_link, [fn -> boot_initial_zones() end]},
        restart: :temporary
      }
    ]

    opts = [strategy: :one_for_one, name: MultiplayerEngine.Supervisor]
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
      MultiplayerEngine.WorldSupervisor.start_zone(zone_id)
    end)
  end
end
