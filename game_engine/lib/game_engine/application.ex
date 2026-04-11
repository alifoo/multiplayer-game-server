defmodule GameEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: GameEngine.Worker.start_link(arg)
      # {GameEngine.Worker, arg}
      {Registry, keys: :unique, name: GameEngine.Registry},
      GameEngine.WorldSupervisor,
      GameEngine.PlayerSupervisor
    ]

    opts = [strategy: :one_for_one, name: GameEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
