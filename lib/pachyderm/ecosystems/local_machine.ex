defmodule Pachyderm.Ecosystems.LocalMachine do

  def participate(ref \\ make_ref()) do
    # Pachyderm Supervisor guarantees only one supervisor per ecosystem
    # WorkerSupervisor guarantees only one worker per entity
    worker_sup_spec = Supervisor.child_spec(%{
      id: {WorkerSupervisor, ref},
      start: {Supervisor, :start_link, [[], [strategy: :one_for_one]]},
      type: :supervisor
    }, %{})
    task_sup_spec = Supervisor.child_spec(%{
      id: {TaskSupervisor, ref},
      start: {Task.Supervisor, :start_link, []},
      type: :supervisor}, %{})
    p1 = Supervisor.start_child(Pachyderm.Ecosystem.LocalMachine.Supervisor, worker_sup_spec)
    |> case  do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
    p2 = Supervisor.start_child(Pachyderm.Ecosystem.LocalMachine.Supervisor, task_sup_spec)
    |> case  do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
    %{worker_supervisor: p1, task_supervisor: p2, ref: ref}
  end

  # def send(address, message, ecosystem \\ Pachyderm.ecosystem(:default)) do
  #
  # end
  def send_sync(address, message, ecosystem) do
    Pachyderm.Agent.activate(get(address, ecosystem), message)
  end

  def follow(address, ecosystem) do
    Pachyderm.Agent.follow(get(address, ecosystem), self())
  end

  # Can do one for rest because it is not a problem id task supervisor lost
  def get({kind, entity_id}, ecosystem) do
    child_spec = %{
      id: {kind, entity_id},
      start: {Pachyderm.Agent, :start_link, [kind, entity_id, ecosystem]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }
    case Supervisor.start_child(ecosystem.worker_supervisor, child_spec) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
  end

  defp default_ref() do
    {:ok, binary} = "8372000364000D6E6F6E6F6465406E6F686F7374000003541DF01C00014E0A33B9" |> Base.decode16
    :erlang.binary_to_term(binary)
  end
end
