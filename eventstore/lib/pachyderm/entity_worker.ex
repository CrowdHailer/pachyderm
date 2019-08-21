defmodule Pachyderm.EntityWorker do
  @behaviour GenServer

  def start_link(entity_id, config) do
    GenServer.start_link(__MODULE__, %{config: config, entity_id: entity_id},
      name: {:global, entity_id}
    )
  end

  @doc false
  def start_supervised(config, entity_id) do
    start_link(entity_id, config)
  end

  @impl GenServer
  def init(init) do
    %{config: config, entity_id: entity_id} = init

    # Need to start the subscription before hand
    {:ok, storage_events} =
      case EventStore.read_stream_forward(entity_id, 0) do
        {:ok, storage_events} ->
          {:ok, storage_events}

        {:error, :stream_not_found} ->
          {:ok, []}
      end

    events = Enum.map(storage_events, & &1.data)
    entity_state = Enum.reduce(events, %{count: 0}, &Example.Counter.apply/2)

    {:ok,
     %{
       entity_state: entity_state,
       events: events,
       followers: %{},
       config: config,
       entity_id: entity_id
     }}
  end

  def handle_call({:message, message}, _from, state) do
    %{
      entity_state: entity_state,
      events: saved_events,
      followers: followers,
      config: config,
      entity_id: entity_id
    } = state

    case Example.Counter.execute(message, entity_state) do
      {:ok, reaction} ->
        {actions, new_events} =
          case reaction do
            {actions, new_events} ->
              {actions, new_events}

            new_events when is_list(new_events) ->
              {[], new_events}
          end

        events = saved_events ++ new_events
        # Correlation vs causation
        # Also what is metadata
        # TODO test validity of actions before saving events
        storage_events =
          for event <- new_events do
            %EventStore.EventData{event_type: nil, data: event}
          end

        :ok = EventStore.append_to_stream(entity_id, length(saved_events), storage_events)

        entity_state = Enum.reduce(new_events, entity_state, &Example.Counter.apply/2)

        for {_monitor, follower} <- followers do
          send(follower, {:events, new_events})
        end

        # Could be a struct, but behaviour more sensible than protocol
        for {action_module, action_payload} <- actions do
          action_module.dispatch(action_payload, config)
        end

        state = %{state | entity_state: entity_state, events: events}
        {:reply, {:ok, entity_state}, state}
    end
  end

  def handle_call({:follow, cursor}, from, state) do
    %{events: events, followers: followers} = state
    # Any harm in reusing ref for subscription_id, probably actually use the ref from monitoring
    {follower, _ref} = from

    # follow more that once? probably not, but can use monitor as subscription_id
    monitor = Process.monitor(follower)
    followers = Map.put(followers, monitor, follower)

    count = length(events)

    state = %{state | followers: followers}
    {:reply, {:ok, count}, state, {:continue, {:send_follower, follower, events}}}
  end

  def handle_continue({:send_follower, follower, events}, state) do
    send(follower, {:events, events})
    {:noreply, state}
  end
end
