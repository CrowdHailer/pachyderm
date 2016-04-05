defmodule LotteryCorp.Operations.EventStore do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def store(store, uuid, event) do
    GenServer.call(store, {:store, uuid, event})
  end
  def handle_call({:store, ref, event}, _f, log) do
    log = [event | log]
    {:reply, Enum.count(log), log}
  end
end
