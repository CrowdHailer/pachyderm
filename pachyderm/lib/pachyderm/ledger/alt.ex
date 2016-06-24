defmodule Pachyderm.Ledger.Alt do
  use GenServer
  @behaviour Pachyderm.Ledger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, {[], []}, opts)
  end

  def save_entries(adjustments, command, log) do
    reactionId = Enum.count(log) + 1
    reaction = %{command: command, adjustments: adjustments, id: reactionId}
    {reaction, log ++ [reaction]}
  end

  def handle_call({:record, adjustments, command}, _from, {log, followers}) do
    {reaction, log} = save_entries(adjustments, command, log)
    Enum.each(followers, fn (follower) ->
      send follower, {:"$LedgerEntry", reaction}
    end)
    {:reply, {:ok, reaction}, {log, followers}}
  end
end
