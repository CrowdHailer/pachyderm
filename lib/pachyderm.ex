defmodule Pachyderm do
  def call(reference, message, config) do
    {:ok, worker} =
      case Pachyderm.EntitySupervisor.start_worker(Pachyderm.EntitySupervisor, reference) do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}
      end

    Pachyderm.EntityWorker.dispatch(worker, message, config)
  end
end
