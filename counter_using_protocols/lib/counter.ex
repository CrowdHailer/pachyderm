defmodule Counter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %Counter.State.Normal{})
  end

  def command(pid, command) do
    GenServer.call(pid, {:command, command})
  end

  # SERVER CALLBACKS

  def handle_call({:command, command}, _from, state) do
    events = Counter.State.handle_command(state, command)
    IO.inspect(events)
    # Ledger.record(ledger, events, command)
    state = Enum.reduce(events, state, fn (ev, st) ->
      Counter.State.handle_event(st, ev)
    end)
    {:reply, {:ok, state}, state}
  end
end
