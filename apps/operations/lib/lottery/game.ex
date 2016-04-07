defmodule LotteryCorp.Operations.Game do
  alias __MODULE__.State
  use GenServer

  def start_link(uuid, event_store) do
    GenServer.start_link(__MODULE__, {uuid, event_store})
  end

  def add_player(game, player) do
    # here we validate player
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
    # needs to set up an agregate id with event store
    {:ok, {%LotteryCorp.Operations.Game.State{uuid: uuid}, event_store}}
  end

  def handle_call(:get_state, _from, {state, event_store}) do
    {:reply, {:ok, state}, {state, event_store}}
  end
  def handle_call(command, _from, {state = %{uuid: uuid}, event_store}) do
    case State.issue_command(command, state) do
      {:ok, event} ->
        transaction = LotteryCorp.Operations.EventStore.store(event_store, uuid, event)
        new_state = State.apply_event(event, state)
        {:reply, {:ok, transaction}, {new_state, event_store}}
      {:error, reason} ->
        {:reply, {:error, reason}, {state, event_store}}
    end
  end
end
