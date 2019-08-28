defmodule Counter do
  @behaviour Pachyderm.Entity
  alias Counter.Increased

  def new() do
    {__MODULE__, UUID.uuid4()}
  end

  @impl Pachyderm.Entity
  def init() do
    %{count: 0}
  end

  @impl Pachyderm.Entity
  def handle(:increment, state) do
    %{count: count} = state
    events = [%Increased{amount: 1}]

    if count + 1 == 5 do
      effects = [{Counter.Mailer, %{alert: 5}}]
      {:ok, {events, effects}}
    else
      {:ok, events}
    end
  end

  @impl Pachyderm.Entity
  def update(%Increased{amount: 1}, state) do
    %{count: count} = state
    count = count + 1
    %{state | count: count}
  end
end
