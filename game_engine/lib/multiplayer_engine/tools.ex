defmodule MultiplayerEngine.LoadTester do
  def spawn_horde(count) do
    zones = [:zone_1, :zone_2, :zone_3, :zone_4, :zone_5]
    IO.puts("Spawning #{count} players...")

    Enum.each(1..count, fn i ->
      player_id = "bot_#{i}_#{Integer.mod(:os.system_time(:millisecond), 10000)}"

      zone_id = Enum.random(zones)
      MultiplayerEngine.PlayerSupervisor.create_player(player_id, zone_id)
    end)

    IO.puts("Finished spawning #{count} players.")
  end

  def spawn_dungeon_run(count) do
    zones = [:zone_1, :zone_2, :zone_3, :zone_4, :zone_5]
    IO.puts("Spawning #{count} players and queueing for dungeons...")

    player_ids =
      Enum.map(1..count, fn i ->
        player_id = "bot_#{i}_#{Integer.mod(:os.system_time(:millisecond), 10000)}"
        zone_id = Enum.random(zones)
        MultiplayerEngine.PlayerSupervisor.create_player(player_id, zone_id)
        player_id
      end)

    Enum.each(player_ids, fn player_id ->
      result = MultiplayerEngine.Matchmaker.join_queue(player_id)

      case result do
        {:matched, dungeon_id, party} ->
          IO.puts("[MATCHED] Dungeon #{dungeon_id} with #{inspect(party)}")

        {:queued, pos, total} ->
          IO.puts("[QUEUED] #{player_id} (#{pos}/#{total})")
      end
    end)

    IO.puts("Finished. #{div(count, 3)} dungeon(s) created, #{rem(count, 3)} player(s) still in queue.")
  end
end

defmodule MultiplayerEngine.ChaosMonkey do
  def unleash(interval_ms \\ 3000) do
    IO.puts("Unleashing Chaos Monkey with interval #{interval_ms} ms...")
    spawn(fn -> loop(interval_ms) end)
  end

  defp loop(interval_ms) do
    :timer.sleep(interval_ms)

    case Enum.random([:player, :zone]) do
      :player ->
        random_kill(MultiplayerEngine.PlayerSupervisor, "Player")

      :zone ->
        random_kill(MultiplayerEngine.WorldSupervisor, "ZoneServer")
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

        case Registry.keys(MultiplayerEngine.Registry, target_pid) do
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

defmodule MultiplayerEngine.Stats do
  def report do
    memory = :erlang.memory()
    player_count = length(DynamicSupervisor.which_children(MultiplayerEngine.PlayerSupervisor))
    zone_count = length(DynamicSupervisor.which_children(MultiplayerEngine.WorldSupervisor))
    dungeon_count = length(DynamicSupervisor.which_children(MultiplayerEngine.DungeonSupervisor))
    total_processes = :erlang.system_info(:process_count)

    IO.puts("\n" <> String.duplicate("=", 55))
    IO.puts("GAME ENGINE MEMORY REPORT")
    IO.puts(String.duplicate("=", 55))

    IO.puts("\n-- BEAM VM Memory --")
    IO.puts("  Total:      #{format_bytes(memory[:total])}")
    IO.puts("  Processes:  #{format_bytes(memory[:processes])}")
    IO.puts("  ETS tables: #{format_bytes(memory[:ets])}")
    IO.puts("  Atoms:      #{format_bytes(memory[:atom])}")
    IO.puts("  Binary:     #{format_bytes(memory[:binary])}")
    IO.puts("  Code:       #{format_bytes(memory[:code])}")

    IO.puts("\n-- Process Count --")
    IO.puts("  BEAM total:   #{total_processes}")
    IO.puts("  Players:      #{player_count}")
    IO.puts("  Zones:        #{zone_count}")
    IO.puts("  Dungeons:     #{dungeon_count}")

    if player_count > 0 do
      avg_player_mem = avg_process_memory(MultiplayerEngine.PlayerSupervisor)

      IO.puts("\n-- Per-Player Memory --")
      IO.puts("  Avg per player: #{format_bytes(avg_player_mem)}")
      IO.puts("  All players:    #{format_bytes(avg_player_mem * player_count)}")
    end

    IO.puts(String.duplicate("=", 55) <> "\n")
  end

  defp avg_process_memory(supervisor) do
    children = DynamicSupervisor.which_children(supervisor)

    if children == [] do
      0
    else
      total =
        Enum.reduce(children, 0, fn {:undefined, pid, _, _}, acc ->
          case Process.info(pid, :memory) do
            {:memory, mem} -> acc + mem
            nil -> acc
          end
        end)

      div(total, length(children))
    end
  end

  defp format_bytes(bytes) when bytes < 1_024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1_024, 2)} KB"
  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_048_576, 2)} MB"
end
