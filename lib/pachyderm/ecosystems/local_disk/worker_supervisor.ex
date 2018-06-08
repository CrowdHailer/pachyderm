defmodule Pachyderm.Ecosystems.LocalDisk.WorkerSupervisor do
  @moduledoc false

  def child_spec(ecosystem_id) do
    %{
      id: ecosystem_id,
      start:
        {Supervisor, :start_link,
         [[], [strategy: :one_for_one]]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end
end
