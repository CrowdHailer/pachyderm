defmodule Pachyderm.Ecosystems.PgBacked do
  # Think ecosystem_supervisor can be the same for all ecosystems, ecosystem just needs to return ref
  # Think worker and supervisor can be the same for all ecosystems and we solve the problem in naming

  def participate(:default) do
    # Pulls all the config for defaults
    # Start running at boot time
    :default
  end

  def participate(_) do
    raise "Only a single ecosystem can be hosted with DbCoordination"
  end

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

  def get_worker(address, :default) do
    case DynamicSupervisor.start_child(__MODULE__.WorkerSupervisor, {__MODULE__.Singleton, {{:default, :not_a_pid}, address}}) do
      {:ok, pid} ->
        pid

      # TODO there is a case of :undefined that is possible here.
      # It will occur when the DB lock is take but this nodes global is not aware of the process
      {:error, {:already_started, pid}} when is_pid(pid) ->
        pid
    end
  end

  @spec whereis_name(integer) :: pid() | :undefined

  def whereis_name({_kind, id}) when is_integer(id) do
    :global.whereis_name(id)
  end

  def register_name({_, id}, pid) do
    pg_session = Pachyderm.Ecosystems.PgBacked.PgSession
    case lock(pg_session, id) do
      :yes ->
        :global.register_name(id, pid)
      :no ->
        :no
    end
  end

  defp lock(pg_session, entiy_id) do
    Postgrex.query!(pg_session, "SELECT pg_advisory_lock(1, $1)", [entiy_id], [timeout: 500])
    :yes
  rescue
    _e in DBConnection.ConnectionError ->
      :no
  end

  defp default_ecosystem() do
    :default
  end
end
