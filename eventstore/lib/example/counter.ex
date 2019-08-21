defmodule Example.Mailer do
  def dispatch(message, %{test: pid}) do
    send(pid, message)
  end
end

defmodule Example.Counter do
  @behaviour Pachyderm.Entity

  defmodule Increased do
    defstruct [:amount]
  end

  @impl Pachyderm.Entity
  def execute(:increment, state) do
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
    %{count: count} = state
    count = count + 1
    %{state | count: count}
  end
end
