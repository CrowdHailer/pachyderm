defmodule Pachyderm.Entity.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, args) do
    Supervisor.start_child(supervisor, args)
  end

  def init(:ok) do
    # Note the args passed to worker spec are appended with args added as superviror start args
    children = [
      worker(Pachyderm.Entity, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
