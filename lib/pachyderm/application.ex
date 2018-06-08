defmodule Pachyderm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Pachyderm.Ecosystems.LocalDisk.EcosystemSupervisor
    ]

    opts = [strategy: :one_for_one, name: Pachyderm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
