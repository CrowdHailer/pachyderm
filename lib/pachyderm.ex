defmodule Pachyderm do
  def send(reference, message, config) do
    # Probably handle started or not in the top level BECAUSE queries wouldn't
    {:ok, worker} =
      case Pachyderm.EntitySupervisor.start_worker(Pachyderm.EntitySupervisor, reference) do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}
      end

    Pachyderm.EntityWorker.dispatch(worker, message, config)
  end

  # This might not survive as a feature, just read from event source
  # def follow(supervisor, reference, cursor) do
  #   {:ok, pid} = Pachyderm.EntitySupervisor.start_worker(supervisor, reference)
  #   GenServer.call(pid, {:follow, cursor})
  # end

  # network identifier ->
end
