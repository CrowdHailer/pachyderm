defmodule Pachyderm.Agent do
  @moduledoc """
  Does work on behalf of some user specified entity
  TODO rename runner/worker
  """

  use GenServer

  @enforce_keys [:kind, :entity_id, :task_supervisor, :logic_state]
  defstruct @enforce_keys

  # Don't start agent with runtime config because that is not permanent
  def start_link(kind, entity_id, task_supervisor) do
    GenServer.start_link(__MODULE__, {kind, entity_id, task_supervisor})
  end

  def init({kind, entity_id, task_supervisor}) do
    group_id = {kind, entity_id}
    :ok = :pg2.create(group_id)

    {:ok,
     %__MODULE__{
       kind: kind,
       entity_id: entity_id,
       task_supervisor: task_supervisor,
       logic_state: kind.init()
     }}
  end

  def activate(pid, message) do
    GenServer.call(pid, {:activate, message})
  end

  def follow(pid, follower) do
    GenServer.call(pid, {:follow, follower})
  end

  def handle_call({:activate, message}, _from, state) do
    # Run in a task
    task =
      Task.Supervisor.async_nolink(state.task_supervisor, state.kind, :activate, [
        message,
        state.logic_state
      ])

    case Task.yield(task) do
      {:ok, logic_state} ->
        state = %{state | logic_state: logic_state}
        group_id = {state.kind, state.entity_id}

        for follow <- :pg2.get_members(group_id) do
          send(follow, {group_id, logic_state})
        end

        {:reply, {:ok, logic_state}, state}
    end
  end

  def handle_call({:follow, follower}, _from, state) do
    group_id = {state.kind, state.entity_id}
    :ok = :pg2.join(group_id, follower)
    {:reply, {:ok, state.logic_state}, state}
  end
end
