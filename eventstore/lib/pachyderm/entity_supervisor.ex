defmodule Pachyderm.EntitySupervisor do
  def start_link(entity_config, options \\ []) do
    DynamicSupervisor.start_link(
      [strategy: :one_for_one, extra_arguments: [entity_config]] ++ Keyword.take(options, [:name])
    )
  end

  # get_worker
  # find_worker -> perhaps this module should only return already started a higher level for integration
  # When two started, i.e. pulled from pg2, hash pid and kill one with lower hash
  def start_worker(supervisor, entity) do
    starting =
      DynamicSupervisor.start_child(supervisor, %{
        # Why does DynamicSupervisor require an id, you cannot delete by it.
        id: nil,
        start: {Pachyderm.EntityWorker, :start_supervised, [entity]}
      })

    case starting do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end
end
