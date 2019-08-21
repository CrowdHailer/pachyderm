defmodule Pachyderm do
  def deliver(supervisor, entity, message) do
    # Probably handle started or not in the top level BECAUSE queries wouldn't
    {:ok, worker} = Pachyderm.EntitySupervisor.start_worker(supervisor, entity)
    Pachyderm.EntityWorker.dispatch(worker, message)
  end

  # This might not survive as a feature, just read from event source
  def follow(supervisor, entity, cursor) do
    {:ok, pid} = Pachyderm.EntitySupervisor.start_worker(supervisor, entity)
    GenServer.call(pid, {:follow, cursor})
  end

  # network identifier ->
end
