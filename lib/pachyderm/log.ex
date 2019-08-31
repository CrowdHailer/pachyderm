defmodule Pachyderm.Log do
  def append(_entity, _expected_version, []) do
    # TODO do you actually want a warning about not being in up to date if saving would fail?
    :ok
  end

  def append(entity, expected_version, new_events) do
    {_module, entity_id} = entity

    storage_events =
      for event <- new_events do
        %EventStore.EventData{event_type: nil, data: event}
      end

    :ok = EventStore.append_to_stream(entity_id, expected_version, storage_events)
  end

  def subscribe(entity) do
    # Is there any interruption API for if a subscription connection is lost,
    # Do transient subscriptions work
    # Need to start the subscription before hand
    {_module, entity_id} = entity
    :ok = EventStore.subscribe(entity_id)
    EventStore.read_stream_forward(entity_id, 0)
  end
end
