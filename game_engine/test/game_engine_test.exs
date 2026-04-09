defmodule GameEngineTest do
  use ExUnit.Case
  doctest GameEngine

  test "greets the world" do
    assert GameEngine.hello() == :world
  end
end
