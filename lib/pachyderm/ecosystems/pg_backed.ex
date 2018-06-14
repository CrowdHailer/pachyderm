defmodule Pachyderm.Ecosystems.PgBacked do
  # Think ecosystem_supervisor can be the same for all ecosystems, ecosystem just needs to return ref
  # Think worker and supervisor can be the same for all ecosystems and we solve the problem in naming

  alias Pachyderm.Ecosystems.PgBacked

  def child_spec(opts) do
    options = Keyword.take(opts, [:name])
    ecosystem_id = Keyword.get(opts, :ecosystem_id, default_ecosystem_id())
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [ecosystem_id, options]},
      type: :supervisor
    }
  end

  def start_link(ecosystem_id, options \\ []) do
    PgBacked.Supervisor.start_link(ecosystem_id, options)
  end
  # We use participate so we can pass around ecosystem id which is permantent

  @doc """
  Reliably send a message to activate an entity.

  This call returns the new state of the entity
  """
  def send_sync(address, message, ecosystem \\ default_ecosystem()) do
    GenServer.call(get_worker(address, ecosystem), {:send, message})
  end

  @doc false
  def send(address, message, ecosystem \\ default_ecosystem()) do
    GenServer.cast(get_worker(address, ecosystem), {:send, message})
  end

  def follow(address, ecosystem \\ default_ecosystem()) do
    GenServer.call(get_worker(address, ecosystem), {:follow, self()})
  end

  # via_tuple does not start the process if it does not exist
  def via_tuple(address, ecosystem \\ default_ecosystem()) do
    {:via, PgBacked.Registry, {address, ecosystem}}
  end

  def get_worker(address, ecosystem) do
    worker_supervisor = PgBacked.Supervisor.worker_supervisor(ecosystem.supervisor)

    # If there was a good way to register pids externally you could start anything at this point
    case DynamicSupervisor.start_child(worker_supervisor, {
      PgBacked.Worker, {address, ecosystem}
    }) do
      {:ok, pid} ->
        pid

      # TODO there is a case of :undefined that is possible here.
      # It will occur when the DB lock is take but this nodes global is not aware of the process
      {:error, {:already_started, pid}} when is_pid(pid) ->
        pid
    end
  end

  def default_ecosystem_id() do
    __MODULE__
  end

  def default_ecosystem() do
    %{
      supervisor: __MODULE__,
      id: default_ecosystem_id()
    }
  end
end
