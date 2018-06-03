defmodule Pachyderm do
  defmodule Agent do
    @moduledoc """
    Does work on behalf of some user specified entity
    """

    use GenServer

    @enforce_keys [:entity, :task_supervisor, :logic_state]
    defstruct @enforce_keys

    # Don't start agent with runtime config because that is not permanent
    def start_link(entity, task_supervisor) do
      GenServer.start_link(__MODULE__, %__MODULE__{
        entity: entity,
        task_supervisor: task_supervisor,
        logic_state: nil
      })
    end

    def init(initial = %__MODULE__{entity: module}) do
      {:ok, %{initial | logic_state: module.init()}}
    end

    def execute(pid, request) do
      IO.inspect(pid)
      GenServer.call(pid, request)
    end

    def handle_call(msg, _from, state) do
      # Run in a task
      task =
        Task.Supervisor.async_nolink(state.task_supervisor, state.entity, :execute, [
          msg,
          state.logic_state
        ])
      case Task.yield(task) do
        {:ok, logic_state} ->
          state = %{state | logic_state: logic_state}
          {:reply, {:ok, logic_state}, state}
      end
    end
  end

  def start_link() do
    # NOTE Dynamic supervisor is not idempotent
    # NOTE children must be temporary
    Supervisor.start_link([], strategy: :one_for_one)
  end

  def execute(module, id, request) do
    Agent.execute(get(module, id), request)
  end

  # In the future we can have a context
  def get(entity, id) do
    # TODO check entity implements correct type
    agent_supervisor = Pachyderm.AgentSupervisor
    task_supervisor = Pachyderm.TaskSupervisor

    child_spec = %{
      id: {entity, id},
      start: {Agent, :start_link, [entity, task_supervisor]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }

    case Supervisor.start_child(agent_supervisor, child_spec) do
      {:ok, pid} ->
        pid
      {:error, {:already_started, pid}} ->
        pid
    end
  end
end
