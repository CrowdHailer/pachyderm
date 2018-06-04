defmodule Pachyderm.EntitySupervisor do
  def child_spec(name: name) do
    %{
      id: __MODULE__,
      start: {Supervisor, :start_link, [[], [strategy: :one_for_one, name: name]]},
      type: :supervisor
    }
  end
end
