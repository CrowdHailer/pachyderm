defmodule Pachyderm do
  @moduledoc """
  Documentation for Pachyderm.
  """

  def activate(id, message) do
    Pachyderm.Agent.activate(get(id), message)
  end

  # In the future we can have a context
  def get(id = {kind, entity_id}) do
    # TODO check kind implements correct type
    entity_supervisor = Pachyderm.EntitySupervisor
    task_supervisor = Pachyderm.TaskSupervisor

    child_spec = %{
      id: {kind, entity_id},
      start: {Pachyderm.Agent, :start_link, [kind, task_supervisor]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }

    case Supervisor.start_child(entity_supervisor, child_spec) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
  end
end
