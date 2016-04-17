defmodule LotteryCorp.Operations.EventStore do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :no_state, opts)
  end

  def persist(event_store, channel, event) do
    GenServer.call(event_store, {:persist, channel, event})
  end

  ## SERVER CALLBACKS

  def init(:no_state) do
    {:ok, {0, [], []}}
  end

  def handle_call({:persist, channel, event}, _f, {count, log, followers}) do
    count = count + 1
    entry = {count, channel, event}
    Enum.each(followers, fn (follower) ->
      send follower, {:"$LedgerEntry", entry}
    end)
    {:reply, {:ok, count}, {count, log ++ [entry], followers}}
  end
end
