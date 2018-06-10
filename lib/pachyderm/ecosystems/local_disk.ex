defmodule Pachyderm.Ecosystems.LocalDisk do
  @moduledoc """
  An ecosystem that runs on a single node only.

  Worker uniqueness is coordinated by the supervision tree.
  Persistance of worker state is to disk, managed by using dets.

  This implementation hits the supervisors alot.
  We either need an ets backed dynamic supervisor or some combination of registry and dynamic supervisor
  """

  alias Pachyderm.Ecosystems.LocalDisk.WorkerSupervisor
  alias Pachyderm.Ecosystems.LocalDisk.Worker

  @ecosystem_supervisor Pachyderm.Ecosystems.LocalDisk.EcosystemSupervisor

  @doc """
  Return the reference to an ecosystem.

  This call will start the ecosystems supervision if it is not already running.
  """
  def participate(ecosystem_id) do
    case Supervisor.start_child(@ecosystem_supervisor, {WorkerSupervisor, ecosystem_id}) do
      {:ok, pid} ->
        {ecosystem_id, pid}

      {:error, {:already_started, pid}} ->
        {ecosystem_id, pid}
    end
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

  @doc """
  Receive updates whenever this entity state changes.

  This call returns the current state of the entity
  Messages are received in the format `{address, state}`
  """
  def follow(address, ecosystem \\ default_ecosystem()) do
    GenServer.call(get_worker(address, ecosystem), {:follow, self()})
  end

  defp get_worker(address, {ecosystem_id, supervisor}) do
    case Supervisor.start_child(supervisor, {Worker, {{ecosystem_id, supervisor}, address}}) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
  end

  defp default_ecosystem() do
    {:ok, binary} =
      "8372000364000D6E6F6E6F6465406E6F686F7374000003541DF01C00014E0A33B9" |> Base.decode16()

    participate(:erlang.binary_to_term(binary))
  end
end
