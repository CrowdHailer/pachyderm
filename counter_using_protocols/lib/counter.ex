defmodule Counter do
  use GenServer

  def start_link(ledger) do
    GenServer.start_link(__MODULE__, ledger)
  end

  def command(pid, command) do
    GenServer.call(pid, {:command, command})
  end

  # SERVER CALLBACKS
  def init(ledger) do
    case Counter.Ledger.inspect(ledger, self) do
      {:ok, 0} ->
        {:ok, {%Counter.State.Normal{}, ledger}}
      {:ok, count} ->
        # propably should handle catchup in a special manner
        {:ok, {%Counter.State.Normal{}, ledger}}

    end
  end

  def handle_call({:command, command}, _from, {state, ledger}) do
    events = Counter.State.handle_command(state, command)
    {:ok, id} = Counter.Ledger.record(ledger, events, command)
    receive do
      {:"$LedgerEntry", %{id: ^id}} ->
    end
    state = Enum.reduce(events, state, fn (ev, st) ->
      Counter.State.handle_event(st, ev)
    end)
    {:reply, {:ok, state}, {state, ledger}}
  end

  def handle_info({:"$LedgerEntry", %{adjustments: adjustments}}, {state, ledger}) do
    state = Enum.reduce(adjustments, state, fn (adjustment, state) ->
      Counter.State.handle_event(state, adjustment)
    end)
    {:noreply, {state, ledger}}
  end
end
