defmodule Pachyderm.EntityWorker do
  @behaviour GenServer

  alias Pachyderm.Entity
  alias Pachyderm.Effect
  alias Pachyderm.Log

  @enforce_keys [
    :reference,
    :events,
    :entity_state
  ]

  defstruct @enforce_keys

  def start_link(reference) do
    GenServer.start_link(__MODULE__, %{reference: reference}, name: {:global, reference})
  end

  def dispatch(worker, message, config) do
    GenServer.call(worker, {:dispatch, message, config})
  end

  @impl GenServer
  def init(init) do
    %{reference: reference} = init

    # If down just read from cursor.
    # By default always handle double events
    {:ok, storage_events} =
      case Log.subscribe(reference) do
        {:ok, storage_events} ->
          {:ok, storage_events}

        {:error, :stream_not_found} ->
          {:ok, []}
      end

    events = Enum.map(storage_events, & &1.data)
    entity_state = Entity.reduce(reference, events)

    {:ok,
     %__MODULE__{
       reference: reference,
       # Don't think I need events, but use as count
       events: events,
       entity_state: entity_state
     }}
  end

  @impl GenServer
  def handle_call({:dispatch, message, config}, _from, state) do
    %__MODULE__{
      reference: reference,
      events: saved_events,
      entity_state: entity_state
    } = state

    case Entity.handle(reference, message, entity_state) do
      {:ok, {new_events, effects}} ->
        :ok = Pachyderm.Log.append(reference, length(saved_events), new_events)

        # TODO test validity of actions before saving events
        events = saved_events ++ new_events
        entity_state = Entity.reduce(reference, new_events, entity_state)

        :ok = Effect.dispatch_all(effects, config)

        state = %{state | entity_state: entity_state, events: events}
        {:reply, {:ok, entity_state}, state}
    end
  end

  @impl GenServer
  def handle_info({:events, recorded_events}, state) do
    state = catchup(recorded_events, state)
    {:noreply, state}
  end

  defp catchup([], state) do
    state
  end

  defp catchup([recorded_event | rest], state) do
    %EventStore.RecordedEvent{stream_version: entity_version, data: event} = recorded_event
    %{reference: reference, events: events, entity_state: entity_state} = state

    state =
      case entity_version - length(events) do
        diff when diff <= 0 ->
          state

        1 ->
          entity_state = Entity.reduce(reference, [event], entity_state)
          events = events ++ [event]

          %{state | events: events, entity_state: entity_state}
      end

    catchup(rest, state)
  end
end
