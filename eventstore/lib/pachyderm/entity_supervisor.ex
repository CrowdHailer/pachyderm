defmodule Pachyderm.EntitySupervisor do
  def child_spec(options) do
    %{
      # id should be network_id in future
      id: __MODULE__,
      start: {__MODULE__, :start_link, [options]},
      type: :supervisor
    }
  end

  def start_link(options \\ []) do
    DynamicSupervisor.start_link(
      [strategy: :one_for_one, extra_arguments: []] ++ Keyword.take(options, [:name])
    )
  end

  # When two started, i.e. pulled from pg2, hash pid and kill one with lower hash
  def start_worker(supervisor, reference) do
    DynamicSupervisor.start_child(supervisor, %{
      # Why does DynamicSupervisor require an id, you cannot delete by it.
      id: nil,
      start: {Pachyderm.EntityWorker, :start_link, [reference]}
    })
  end
end
