defmodule Pachyderm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Pachyderm.Ecosystems.LocalDisk.EcosystemSupervisor,
      # TODO move childspec to ecosystem module
      %{
        id: Pachyderm.Ecosystem.LocalMachine.Supervisor,
        start:
          {Supervisor, :start_link,
           [[], [strategy: :one_for_one, name: Pachyderm.Ecosystem.LocalMachine.Supervisor]]},
        type: :supervisor,
        restart: :permanent,
        shutdown: 500
      }
    ]

    opts = [strategy: :one_for_one, name: Pachyderm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
