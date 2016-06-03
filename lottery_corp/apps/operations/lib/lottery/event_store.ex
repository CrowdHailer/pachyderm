defmodule LotteryCorp.Operations.EventStore do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :no_state, opts)
  end

  def persist(event_store, channel, event) do
    GenServer.call(event_store, {:persist, channel, event})
  end

  def follow(ledger, follower) do
    GenServer.call(ledger, {:follow, follower})
  end

  def monitor(ledger, follower) do
    GenServer.call(ledger, {:monitor, follower})
  end

  ## SERVER CALLBACKS

  def init(:no_state) do
    {:ok, {0, [], []}}
  end

  def handle_call({:persist, channel, event}, _f, {count, log, followers}) do
    count = count + 1
    entry = {count, channel, event}
    Enum.each(followers, fn (follower) ->
      send follower, {:"$EntryPersisted", entry}
    end)
    {:reply, {:ok, count}, {count, log ++ [entry], followers}}
  end
  def handle_call({:follow, follower}, _from, {last, log, followers}) do
    Enum.each(log, fn (entry) ->
      send follower, {:"$EntryPersisted", entry}
    end)
    {:reply, {:ok, last}, {last, log, followers ++ [follower]}}
  end
  def handle_call({:monitor, follower}, _from, {last, log, followers}) do
    {:reply, {:ok, last}, {last, log, followers ++ [follower]}}
  end
end
