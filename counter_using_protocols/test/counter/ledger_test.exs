

defmodule Counter.LedgerTest do
  alias Counter.Ledger
  use ExUnit.Case
  # Optimistic concurrency assume that ledger and counter are in sync
  test "first ledger entry should have id 1" do
    response = Ledger.handle_call({:record, [:event], :command}, :from, {[], []})
    {:reply, {:ok, count}, state} = response
    assert count == 1
  end

  test "ledger" do
    {:ok, ledger} = Ledger.start_link()
    {:ok, count} = Ledger.record(ledger, [:event1, :event2], :command)
    IO.inspect count
    {:ok, count} = Ledger.inspect(ledger, self)
    receive do
      msg -> IO.inspect msg
    end
  end
end
