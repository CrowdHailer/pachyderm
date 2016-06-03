

defmodule CounterTest do
  use ExUnit.Case

  test "the truth" do
    counter_state = %Counter.State.Normal{}
    IO.inspect counter_state
    events = Counter.State.handle_command(counter_state, %Counter.Command.Increment{})
    IO.inspect(events)
    events = Counter.State.handle_command(counter_state, %Counter.Command.SuperCharge{})
    IO.inspect(events)
    state = Counter.State.handle_event(counter_state, %Counter.Event.Incremented{amount: 3})
    state = Counter.State.handle_event(state, %Counter.Event.SuperCharged{})
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
