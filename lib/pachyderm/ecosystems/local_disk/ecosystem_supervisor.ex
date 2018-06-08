defmodule Pachyderm.Ecosystems.LocalDisk.EcosystemSupervisor do
  @moduledoc false

  @name Pachyderm.Ecosystems.LocalDisk.EcosystemSupervisor

  def child_spec([]) do
    %{
      id: @name,
      start:
        {Supervisor, :start_link,
         [[], [strategy: :one_for_one, name: @name]]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end
end
