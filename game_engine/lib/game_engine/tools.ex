defmodule GameEngine.LoadTester do
  def spawn_horde(count) do
    zones = [:zone_1, :zone_2, :zone_3, :zone_4, :zone_5]
    IO.puts("Spawning #{count} players...")

    Enum.each(1..count, fn i ->
      player_id = "bot_#{i}_#{Integer.mod(:os.system_time(:millisecond), 10000)}"

      zone_id = Enum.random(zones)
      GameEngine.PlayerSupervisor.create_player(player_id, zone_id)
    end)

    IO.puts("Finished spawning #{count} players.")
  end
end

defmodule GameEngine.ChaosMonkey do
  def unleash(interval_ms \\ 3000) do
    IO.puts("Unleashing Chaos Monkey with interval #{interval_ms} ms...")
    spawn(fn -> loop(interval_ms) end)
  end

  defp loop(interval_ms) do
    :timer.sleep(interval_ms)

    case Enum.random([:player, :zone]) do
      :player ->
        random_kill(GameEngine.PlayerSupervisor, "Player")

      :zone ->
        random_kill(GameEngine.WorldSupervisor, "ZoneServer")
    end

    loop(interval_ms)
  end

  defp random_kill(supervisor, type) do
    children = DynamicSupervisor.which_children(supervisor)

    case children do
      [] ->
        IO.puts("No #{type} processes to kill.")
        :ok

      _ ->
        {:undefined, target_pid, _, _} = Enum.random(children)

        case Registry.keys(GameEngine.Registry, target_pid) do
          [{:player, player_id}] ->
            :ets.insert(:restart_tracker, {player_id, :erlang.monotonic_time(:microsecond)})

          [{:ZoneServer, zone_id}] ->
            :ets.insert(:restart_tracker, {zone_id, :erlang.monotonic_time(:microsecond)})

          _ ->
            :ok
        end

        Process.exit(target_pid, :kill)
    end
  end
end
