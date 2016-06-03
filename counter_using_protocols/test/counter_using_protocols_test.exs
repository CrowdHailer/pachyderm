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

defmodule CounterSuperCharged do
  defstruct total: 0
end

defimpl GenSourced, for: CounterSuperCharged do
  def handle_command(_state, %IncCommand{amount: amount}) do
    [%IncEvent{amount: amount}, %IncEvent{amount: amount}]
  end
  def handle_command(state, %SuperChargeCommand{}) do
    []
  end

  def handle_event(state = %{total: total}, %IncEvent{amount: amount}) do
    %{state | total: total + amount}
  end
end

defmodule Counter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %CounterNormal{})
  end

  def command(pid, command) do
    GenServer.call(pid, {:command, command})
  end

  # SERVER CALLBACKS

  def handle_call({:command, command}, _from, state) do
    events = GenSourced.handle_command(state, command)
    IO.inspect(events)
    state = Enum.reduce(events, state, fn (ev, st) ->
      GenSourced.handle_event(st, ev)
    end)
    {:reply, {:ok, state}, state}
  end
end

defmodule CounterUsingProtocolsTest do
  use ExUnit.Case

  test "the truth" do
    counter_state = %CounterNormal{}
    IO.inspect counter_state
    events = GenSourced.handle_command(counter_state, %IncCommand{})
    IO.inspect(events)
    events = GenSourced.handle_command(counter_state, %SuperChargeCommand{})
    IO.inspect(events)
    state = GenSourced.handle_event(counter_state, %IncEvent{amount: 3})
    state = GenSourced.handle_event(state, %SuperChargedEvent{})
    IO.inspect state

    IO.inspect("Starting")
    {:ok, pid} = Counter.start_link()
    {:ok, state} = Counter.command(pid, %IncCommand{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %SuperChargeCommand{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %IncCommand{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %SuperChargeCommand{})
    IO.inspect(state)
  end
end
