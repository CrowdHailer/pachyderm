defmodule LotteryCorp.Operations.EventStore do
  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def subscribe(store, pid) do
    GenServer.call(store, {:subscribe, pid})
  end

  def store(store, uuid, event) do
    GenServer.call(store, {:store, uuid, event})
  end

  def log(store) do
    GenServer.call(store, :log)
  end

  def init(state) do
    GenEvent.start_link([name: __MODULE__.Broadcast])
    {:ok, state}
  end

  def handle_call({:store, ref, event}, _f, log) do
    log = [{ref, event} | log]
    GenEvent.notify(__MODULE__.Broadcast, {ref, event})
    {:reply, Enum.count(log), log}
  end
  def handle_call({:subscribe, pid}, _f, log) do
    GenEvent.add_handler(__MODULE__.Broadcast, {__MODULE__.Forwarder, pid}, pid)
    {:reply, {:ok, log}, log}
  end
  def handle_call(:log, _f, log) do
    {:reply, {:ok, log}, log}
  end
end
