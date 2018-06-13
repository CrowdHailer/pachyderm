# TODO rename singleton supervisor
defmodule Pachyderm.Ecosystems.PgBacked.WorkerSupervisor do

  def child_spec([]) do
    %{
      id: __MODULE__,
      start: {DynamicSupervisor, :start_link, [[strategy: :one_for_one, name: __MODULE__]]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end
end
