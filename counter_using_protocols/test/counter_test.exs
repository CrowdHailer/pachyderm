defmodule CounterTest do
  use ExUnit.Case
  alias Counter.Command.{Increment, SuperCharge}

  test "the truth" do
    {:ok, ledger} = Counter.Ledger.start_link()
    {:ok, pid} = Counter.start_link(ledger)
    {:ok, state} = Counter.command(pid, %Increment{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %SuperCharge{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %Increment{})
    IO.inspect(state)
    {:ok, state} = Counter.command(pid, %SuperCharge{})
    IO.inspect(state)
    # There is only a single ledger so this is a clone of the counter
    {:ok, pid2} = Counter.start_link(ledger)
    :timer.sleep(1000) 
    {:ok, state} = Counter.command(pid2, %Increment{})
    IO.inspect(state)

  end
end
