defmodule Example.Mailer do
  def dispatch(message, %{test: pid}) do
    send(pid, message)
  end
end

defmodule Example.Counter do
  @behaviour Pachyderm.Entity
  @initial_state %{count: 0}

  def new_address() do
    {__MODULE__, UUID.uuid4()}
  end

  defmodule Increased do
    defstruct [:amount]
  end

  @impl Pachyderm.Entity
  def execute(:increment, state) do
    state = state || @initial_state
    %{count: count} = state
    events = [%Increased{amount: 1}]

    if count + 1 == 5 do
      actions = [{Example.Mailer, %{alert: 5}}]
      {:ok, {actions, events}}
    else
      {:ok, events}
    end
  end

  @impl Pachyderm.Entity
  def apply(%Increased{amount: 1}, state) do
    state = state || @initial_state
    %{count: count} = state
    count = count + 1
    %{state | count: count}
  end
end
