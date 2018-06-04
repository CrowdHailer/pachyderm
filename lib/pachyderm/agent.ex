defmodule Pachyderm.Agent do
  @moduledoc """
  Does work on behalf of some user specified entity
  """

  use GenServer

  @enforce_keys [:entity, :task_supervisor, :logic_state]
  defstruct @enforce_keys

  # Don't start agent with runtime config because that is not permanent
  def start_link(kind, task_supervisor) do
    GenServer.start_link(__MODULE__, {kind, task_supervisor})
  end

  def init({kind, task_supervisor}) do
    {:ok,
     %__MODULE__{
       entity: kind,
       task_supervisor: task_supervisor,
       logic_state: kind.init()
     }}
  end

  def activate(pid, message) do
    GenServer.call(pid, {:activate, message})
  end

  def handle_call({:activate, message}, _from, state) do
    # Run in a task
    task =
      Task.Supervisor.async_nolink(state.task_supervisor, state.entity, :activate, [
        message,
        state.logic_state
      ])

    case Task.yield(task) do
      {:ok, logic_state} ->
        state = %{state | logic_state: logic_state}
        {:reply, {:ok, logic_state}, state}
    end
  end
end
