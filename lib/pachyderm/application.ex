defmodule Pachyderm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Pachyderm.Ecosystems.LocalDisk.EcosystemSupervisor,
      {Pachyderm.Ecosystems.PgBacked, [name: Pachyderm.Ecosystems.PgBacked]},
      # All the PgBacked ones should be in one link
      # # Pachyderm.Ecosystems.PgBacked.Registry,
      # Pachyderm.Ecosystems.PgBacked.PgSession,
      # Pachyderm.Ecosystems.PgBacked.WorkerSupervisor
    ]

    opts = [strategy: :one_for_one, name: Pachyderm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
