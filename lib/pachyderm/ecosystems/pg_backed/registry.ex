defmodule Pachyderm.Ecosystems.PgBacked.Registry do
  use GenServer

  alias Pachyderm.Ecosystems.PgBacked

  def start_link(ecosystem_id) do
    GenServer.start_link(__MODULE__, ecosystem_id)
  end

  def init(ecosystem_id) do
    {:ok, %{ecosystem_id: ecosystem_id, monitors: %{}}}
  end

  @spec whereis_name(integer) :: pid() | :undefined
  def whereis_name({address, ecosystem}) do
    :global.whereis_name({address, ecosystem.id})
  end

  def register_name({address, ecosystem}, pid) do
    PgBacked.Supervisor.registry(ecosystem.supervisor)
    |> register(address, pid, ecosystem)
    |> case do
      :ok ->
        :yes
      {:error, _} ->
        :no
    end
  end

  # ecosystem should be part of state so unregister can be done without passing reft to ecosystem
  def register(register, address, pid, ecosystem) do
    GenServer.call(register, {:register, address, pid, ecosystem})
  end

  def handle_call({:register, address, pid, ecosystem}, _from, state) do
    pg_session = PgBacked.Supervisor.pg_session(my_supervisor())

    # Getting the lock works on a per pg_session basis.
    # global is consistent within a single node
    case lock(pg_session, address, ecosystem) do
      {:ok, lock_id} ->
        case :global.register_name({address, ecosystem.id}, pid) do
          :yes ->
            monitor = Process.monitor(pid)
            state = put_in(state, [:monitors, monitor], lock_id)
            {:reply, :ok, state}
          :no ->
            {:reply, {:error, {:already_registered, :toto}}, state}
        end
      {:error, :lock_timeout} ->
        {:reply, {:error, :lock_timeout}, state}
    end
  end

  def handle_info({:DOWN, monitor, :process, _pid, _reason}, state) do
    pg_session = PgBacked.Supervisor.pg_session(my_supervisor())

    {lock_id, state} = pop_in(state, [:monitors, monitor])
    :ok = unlock(pg_session, lock_id)
    {:noreply, state}
  end

  defp my_supervisor() do
    [parent] = for {:"$ancestors", [parent | _rest]} <- Process.get(), do: parent
    parent
  end

  defp lock(pg_session, address, ecosystem) do
    lock_id = {hash(ecosystem.id), hash(address)}
    Postgrex.query!(
      pg_session,
      "SELECT pg_advisory_lock($1, $2)",
      [elem(lock_id, 0), elem(lock_id, 1)],
      [timeout: 500])
    {:ok, lock_id}
  rescue
    _e in DBConnection.ConnectionError ->
      {:error, :lock_timeout}
  end

  defp unlock(pg_session, lock_id) do
    %Postgrex.Result{rows: [[true]]} = Postgrex.query!(
      pg_session,
      "SELECT pg_advisory_unlock($1, $2)",
      [elem(lock_id, 0), elem(lock_id, 1)],
      [timeout: 500])
    :ok
  end

  defp hash(term) do
    :erlang.phash2(term, :math.pow(2, 31) |> round)
  end
end
