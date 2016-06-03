defprotocol GenSourced do
  def handle_command(state, command)
  def handle_event(state, event)
end

defmodule Counter.Command.Increment do
  defstruct amount: 1
end
defmodule Counter.Command.SuperCharge do
  defstruct []
end
defmodule Counter.Event.Incremented do
  defstruct amount: 1
end
defmodule Counter.Event.SuperCharged do
  defstruct []
end

defmodule Counter.State.Normal do
  defstruct total: 0
end

defimpl GenSourced, for: Counter.State.Normal do
  def handle_command(_state, %Counter.Command.Increment{amount: amount}) do
    [%Counter.Event.Incremented{amount: amount}]
  end
  def handle_command(state, %Counter.Command.SuperCharge{}) do
    [%Counter.Event.SuperCharged{}]
  end

  def handle_event(state = %{total: total}, %Counter.Event.Incremented{amount: amount}) do
    %{state | total: total + amount}
  end
  def handle_event(state, %Counter.Event.SuperCharged{}) do
    %{state | :__struct__ => Counter.State.SuperCharged}
  end
end

defmodule Counter.State.SuperCharged do
  defstruct total: 0
end

defimpl GenSourced, for: Counter.State.SuperCharged do
  def handle_command(_state, %Counter.Command.Increment{amount: amount}) do
    [%Counter.Event.Incremented{amount: amount}, %Counter.Event.Incremented{amount: amount}]
  end
  def handle_command(state, %Counter.Command.SuperCharge{}) do
    []
  end

  def handle_event(state = %{total: total}, %Counter.Event.Incremented{amount: amount}) do
    %{state | total: total + amount}
  end
end

defmodule Counter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %Counter.State.Normal{})
  end

  def command(pid, command) do
    GenServer.call(pid, {:command, command})
  end

  # SERVER CALLBACKS

  def handle_call({:command, command}, _from, state) do
    events = GenSourced.handle_command(state, command)
    IO.inspect(events)
    # Ledger.record(ledger, events, command)
    state = Enum.reduce(events, state, fn (ev, st) ->
      GenSourced.handle_event(st, ev)
    end)
    {:reply, {:ok, state}, state}
  end
end

defmodule CounterTest do
  use ExUnit.Case

  test "the truth" do
    counter_state = %Counter.State.Normal{}
    IO.inspect counter_state
    events = GenSourced.handle_command(counter_state, %Counter.Command.Increment{})
    IO.inspect(events)
    events = GenSourced.handle_command(counter_state, %Counter.Command.SuperCharge{})
    IO.inspect(events)
    state = GenSourced.handle_event(counter_state, %Counter.Event.Incremented{amount: 3})
    state = GenSourced.handle_event(state, %Counter.Event.SuperCharged{})
    IO.inspect state

    IO.inspect("Starting")
    {:ok, pid} = Counter.start_link()
    {:ok, state} = Counter.command(pid, %Counter.Command.Increment{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %Counter.Command.SuperCharge{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %Counter.Command.Increment{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %Counter.Command.SuperCharge{})
    IO.inspect(state)
  end
end
