defmodule LotteryCorp.Operations.Game do
  use GenServer

  alias LotteryCorp.Operations.Game
  alias LotteryCorp.Operations.EventStore

  def start_link(uuid, event_store) do
    GenServer.start_link(__MODULE__, {uuid, event_store})
  end

  def add_player(game, player) do
    command = {:add_player, player}
    GenServer.call(game, command)
  end

  def remove_player(game, player) do
    command = {:remove_player, player}
    GenServer.call(game, command)
  end

  def pick_winner(game) do
    command = {:pick_winner, :random_seed}
    GenServer.call(game, command)
  end

  def get_state(game) do
    GenServer.call(game, :get_state)
  end

  def init({uuid, event_store}) do
    EventStore.follow(event_store, self)
    {:ok, {%Game.State{uuid: uuid}, event_store}}
  end

  def handle_call(:get_state, _from, {state, event_store}) do
    {:reply, {:ok, state}, {state, event_store}}
  end
  def handle_call(command, _from, {state = %{uuid: uuid}, event_store}) do
    case Game.State.issue_command(command, state) do
      {:ok, event} ->
        {:ok, transaction} = EventStore.persist(event_store, uuid, event)
        {:reply, {:ok, transaction}, {state, event_store}}
      {:error, reason} ->
        {:reply, {:error, reason}, {state, event_store}}
    end
  end

  def handle_info({:"$EntryPersisted", {_id, channel, event}}, {state, event_store}) do
    if channel == state.uuid do
      new_state = Game.State.apply_event(event, state)
      {:noreply, {new_state, event_store}}
    else
      {:noreply, {state, event_store}}
    end
  end
end
