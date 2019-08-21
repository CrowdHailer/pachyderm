defmodule Pachyderm do
  def dispatch(id, message) do
    {:ok, pid} = do_start(id)
    GenServer.call(pid, {:message, message})
  end

  def follow(id, cursor) do
    {:ok, pid} = do_start(id)
    GenServer.call(pid, {:follow, cursor})
  end

  defp do_start(id) do
    starting = GenServer.start_link(__MODULE__, nil, name: {:global, id})

    case starting do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  def init(nil) do
    {:ok, %{entity_state: %{count: 0}, events: [], followers: %{}}}
  end

  def handle_call({:message, message}, _from, state) do
    %{entity_state: entity_state, events: saved_events, followers: followers} = state

    case handle(message, entity_state) do
      {:ok, reaction} ->
        {actions, new_events} =
          case reaction do
            {actions, new_events} ->
              {actions, new_events}

            new_events when is_list(new_events) ->
              {[], new_events}
          end

        entity_state = Enum.reduce(new_events, entity_state, &apply_event/2)
        events = saved_events ++ new_events
        # TODO test validity of actions before saving events

        for {_monitor, follower} <- followers do
          send(follower, {:events, new_events})
        end

        # Could be a struct, but behaviour more sensible than protocol
        for {action_module, action_payload} <- actions do
          action_module.dispatch(action_payload)
        end

        state = %{state | entity_state: entity_state, events: events}
        {:reply, {:ok, entity_state}, state}
    end
  end

  def handle_call({:follow, cursor}, from, state) do
    %{events: events, followers: followers} = state
    # Any harm in reusing ref for subscription id, probably actually use the ref from monitoring
    {follower, _ref} = from

    # follow more that once? probably not, but can use monitor as subscription id
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

  defmodule Mailer do
    def dispatch(message) do
      IO.inspect(message)
      send(self(), message)
    end
  end

  defp handle(:increment, state) do
    %{count: count} = state
    events = [%{increased: 1}]

    if count + 1 == 5 do
      actions = [{Mailer, %{alert: 5}}]
      {:ok, {actions, events}}
    else
      {:ok, events}
    end
  end

  defp apply_event(%{increased: 1}, state) do
    %{count: count} = state
    count = count + 1
    %{state | count: count}
  end
end
