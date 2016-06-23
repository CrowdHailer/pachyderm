defmodule Pachyderm.Ledger.InMemory do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, {[], []}, opts)
  end

  def record(adjustments, command, {__MODULE__, ledger}) do
    record(ledger, adjustments, command)
  end
  def record(ledger, adjustments, command) do
    GenServer.call(ledger, {:record, adjustments, command})
  end

  # maybe call this method recover
  def inspect(ledger, follower) do
    GenServer.call(ledger, {:inspect, follower})
  end

  def monitor(ledger, follower) do
    GenServer.call(ledger, {:monitor, follower})
  end

  ## SERVER CALLBACKS

  def handle_call({:record, adjustments, command}, _from, {log, followers}) do
    reactionId = Enum.count(log) + 1
    reaction = %{command: command, adjustments: adjustments, id: reactionId}
    Enum.each(followers, fn (follower) ->
      send follower, {:"$LedgerEntry", reaction}
    end)
    {:reply, {:ok, reaction}, {log ++ [reaction], followers}}
  end
  def handle_call({:inspect, follower}, _from, {log, followers}) do
    Enum.each(log, fn (entry) ->
      send follower, {:"$LedgerEntry", entry}
    end)
    {:reply, {:ok, Enum.count(log)}, {log, followers ++ [follower]}}
  end
  def handle_call({:monitor, follower}, _from, {log, followers}) do
    {:reply, {:ok, Enum.count(log)}, {log, followers ++ [follower]}}
  end
end
