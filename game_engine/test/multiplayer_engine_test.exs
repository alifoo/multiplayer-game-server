defmodule MultiplayerEngineTest do
  use ExUnit.Case
  doctest MultiplayerEngine

  test "greets the world" do
    assert MultiplayerEngine.hello() == :world
  end
end
