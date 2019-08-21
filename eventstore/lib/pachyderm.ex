defmodule Pachyderm do
  def deliver(supervisor, entity_id, message) do
    # Probably handle started or not in the top level BECAUSE queries wouldn't
    {:ok, pid} = Pachyderm.EntitySupervisor.start_worker(supervisor, entity_id)
    GenServer.call(pid, {:message, message})
  end

  def follow(supervisor, entity_id, cursor) do
    {:ok, pid} = Pachyderm.EntitySupervisor.start_worker(supervisor, entity_id)
    GenServer.call(pid, {:follow, cursor})
  end

  # network identifier ->
end
