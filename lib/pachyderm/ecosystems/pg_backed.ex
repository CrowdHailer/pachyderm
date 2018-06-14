defmodule Pachyderm.Ecosystems.PgBacked do
  # Think ecosystem_supervisor can be the same for all ecosystems, ecosystem just needs to return ref
  # Think worker and supervisor can be the same for all ecosystems and we solve the problem in naming

  alias Pachyderm.Ecosystems.PgBacked

  def start_link(ecosystem_id) do
    PgBacked.Supervisor.start_link(ecosystem_id)
  end
  # We use participate so we can pass around ecosystem id which is permantent

  @doc """
  Reliably send a message to activate an entity.

  This call returns the new state of the entity
  """
  def send_sync(address, message, ecosystem) do
    GenServer.call(get_worker(address, ecosystem), {:send, message})
  end

  @doc false
  def send(address, message, ecosystem) do
    GenServer.cast(get_worker(address, ecosystem), {:send, message})
  end

  def follow(address, ecosystem) do
    GenServer.call(get_worker(address, ecosystem), {:follow, self()})
  end

  # via_tuple does not start the process if it does not exist
  def via_tuple(address, ecosystem) do
    {:via, PgBacked.Registry, {address, ecosystem}}
  end

  def get_worker(address, ecosystem) do
    worker_supervisor = PgBacked.Supervisor.worker_supervisor(ecosystem.supervisor)

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
end
