defprotocol GenSourced do
  def handle_command(state, command)
  def handle_event(state, event)
end

defmodule IncCommand do
  defstruct amount: 1
end
defmodule SuperChargeCommand do
  defstruct []
end
defmodule IncEvent do
  defstruct amount: 1
end
defmodule SuperChargedEvent do
  defstruct []
end

defmodule CounterNormal do
  defstruct total: 0
end
defmodule CounterSuperCharged do
  defstruct total: 0
end

defimpl GenSourced, for: CounterNormal do
  def handle_command(_state, %IncCommand{amount: amount}) do
    [%IncEvent{amount: amount}]
  end
  def handle_command(state, %SuperChargeCommand{}) do
    [%SuperChargedEvent{}]
  end

  def handle_event(state = %{total: total}, %IncEvent{amount: amount}) do
    %{state | total: total + amount}
  end
  def handle_event(state, %SuperChargedEvent{}) do
    %{state | :__struct__ => CounterSuperCharged}
  end
end

defmodule CounterUsingProtocolsTest do
  use ExUnit.Case

  test "the truth" do
    counter = %CounterNormal{}
    IO.inspect counter
    events = GenSourced.handle_command(counter, %IncCommand{})
    IO.inspect(events)
    events = GenSourced.handle_command(counter, %SuperChargeCommand{})
    IO.inspect(events)
    state = GenSourced.handle_event(counter, %IncEvent{amount: 3})
    state = GenSourced.handle_event(state, %SuperChargedEvent{})
    IO.inspect state
  end
end
