defmodule Pachyderm do
  def deliver(supervisor, entity, message) do
    # Probably handle started or not in the top level BECAUSE queries wouldn't
    {:ok, pid} = Pachyderm.EntitySupervisor.start_worker(supervisor, entity)
    GenServer.call(pid, {:message, message})
  end

  def follow(supervisor, entity, cursor) do
    {:ok, pid} = Pachyderm.EntitySupervisor.start_worker(supervisor, entity)
    GenServer.call(pid, {:follow, cursor})
  end

  # network identifier ->
end
