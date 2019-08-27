defmodule Pachyderm.EntityWorker do
  @behaviour GenServer

  def start_link(entity, config) do
    GenServer.start_link(__MODULE__, %{config: config, entity: entity}, name: {:global, entity})
  end

  @doc false
  def start_supervised(config, entity) do
    start_link(entity, config)
  end

  def dispatch(worker, message) do
    GenServer.call(worker, {:message, message})
  end

  @impl GenServer
  def init(init) do
    %{config: config, entity: entity} = init
    {entity_module, entity_id} = entity

    # If down just read from cursor.
    # By default always handle double events
    # Is there any interruption API for if a subscription connection is lost,
    # Do transient subscriptions work
    :ok = EventStore.subscribe(entity_id)
    # Need to start the subscription before hand
    {:ok, storage_events} =
      case EventStore.read_stream_forward(entity_id, 0) do
        {:ok, storage_events} ->
          {:ok, storage_events}

        {:error, :stream_not_found} ->
          {:ok, []}
      end

    events = Enum.map(storage_events, & &1.data)
    entity_state = Enum.reduce(events, nil, &entity_module.apply/2)

    {:ok,
     %{
       entity_state: entity_state,
       # Don't think I need events, but use as count
       events: events,
       config: config,
       entity_module: entity_module,
       entity_id: entity_id
     }}
  end

  @impl GenServer
  def handle_call({:message, message}, _from, state) do
    %{
      entity_state: entity_state,
      events: saved_events,
      config: config,
      entity_module: entity_module,
      entity_id: entity_id
    } = state

    case entity_module.execute(message, entity_state) do
      {:ok, reaction} ->
        {actions, new_events} =
          case reaction do
            {actions, new_events} ->
              {actions, new_events}

            new_events when is_list(new_events) ->
              {[], new_events}
          end

        entity = {entity_module, entity_id}
        :ok = Pachyderm.Log.append(entity, length(saved_events), new_events)
        # TODO test validity of actions before saving events
        events = saved_events ++ new_events
        entity_state = Enum.reduce(new_events, entity_state, &entity_module.apply/2)

        # Could be a struct, but behaviour more sensible than protocol
        for {action_module, action_payload} <- actions do
          action_module.dispatch(action_payload, config)
        end

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

  defp catchup(
         [%EventStore.RecordedEvent{stream_version: entity_version, data: event} | rest],
         state = %{
           events: events,
           entity_state: entity_state,
           entity_module: entity_module
         }
       )
       when entity_version - length(events) == 1 do
    events = events ++ [event]

    entity_state = Enum.reduce([event], entity_state, &entity_module.apply/2)

    state = %{state | events: events, entity_state: entity_state}

    catchup(rest, state)
  end

  defp catchup(
         [%EventStore.RecordedEvent{stream_version: entity_version, data: event} | rest],
         state = %{events: events}
       )
       when length(events) >= entity_version do
    catchup(rest, state)
  end
end
