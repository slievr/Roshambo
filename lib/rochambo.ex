defmodule Rochambo do
  use Application

  alias Rochambo.Server

  def start(_type, _opts) do
    children = [
      {Registry, keys: :unique, name: Rochambo.Registry},
      {DynamicSupervisor, name: Rochambo.GameSupervisor, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, name: Rochambo.Supervisor, strategy: :one_for_one)
    Server.start()
  end
end
