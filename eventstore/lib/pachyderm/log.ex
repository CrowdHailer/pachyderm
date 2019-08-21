defmodule Pachyderm.Log do
  def append(entity, expected_version, new_events) do
    {_module, entity_id} = entity

    storage_events =
      for event <- new_events do
        %EventStore.EventData{event_type: nil, data: event}
      end

    :ok = EventStore.append_to_stream(entity_id, expected_version, storage_events)
  end
end
