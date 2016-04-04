defmodule Lottery.EventStore do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, {0, []}, [name: __MODULE__])
  end

  # CALL transaction
  def add_events(store, events) do
    GenServer.call(store, {:add_events, events})
  end

  def handle_call({:add_events, {uuid, [new]}}, _from, {count, events}) do
    IO.inspect(events)
    {:reply, {:ok, count}, {count + 1, events ++ [uuid, new]}}
  end
  def handle_call({:add_events, {uuid, []}}, _from, {count, events}) do
    {:reply, {:ok, count}, {count + 1, events}}
  end
end
