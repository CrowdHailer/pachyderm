defmodule LotteryCorp.Operations.EventStoreTest do
  use ExUnit.Case
  alias LotteryCorp.Operations.EventStore


  test "game" do
    {:ok, store} = EventStore.start_link([])
    {:ok, log} = EventStore.subscribe(store, self)
    transaction_id = EventStore.store(store, :aggregate_id, :some_event)
    receive do
      message -> IO.inspect(message)
    end
  end
end
