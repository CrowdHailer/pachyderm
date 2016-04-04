defmodule Lottery.Game do
  defmodule State do
    defstruct winner: :none, players: [], uuid: :none

    def issue_command({:add_player, player}, %{players: players, winner: :none}) do
      case Enum.member?(players, player) do
        true -> {:ok, :no_change}
        false -> {:ok, {:added_player, player}}
      end
    end
    def issue_command({:remove_player, player}, %{players: players, winner: :none}) do
      case Enum.member?(players, player) do
        true -> {:ok, {:removed_player, player}}
        false -> {:ok, :no_change}
      end
    end
    def issue_command({:pick_winner, _seed}, %{players: []}) do
      {:error, :no_players_to_win}
    end
    def issue_command({:pick_winner, _seed}, %{players: players, winner: :none}) do
      winner = Enum.random(players)
      {:ok, {:picked_winner, winner}}
    end
    def issue_command(_command, %{winner: _winner}) do
      {:error, :lottery_closed}
    end

    def apply_event({:added_player, player}, state = %{players: players}) do
      %{state | players: players ++ [player]}
    end
    def apply_event({:removed_player, player}, state = %{players: players}) do
      %{state | players: Enum.filter(players, fn(p) -> p != player end)}
    end
    def apply_event({:picked_winner, winner}, state = %{winner: :none}) do
      %{state | winner: winner}
    end
    def apply_event(:no_change, state) do
      state
    end
  end
  use GenServer

  def start_link(uuid, event_store) do
    # Should be game id
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

  def init({uuid, event_store}) do
    # needs to set up an agregate id with event store
    {:ok, {%Lottery.Game.State{uuid: uuid}, event_store}}
  end

  def handle_call(command, _from, {state = %{uuid: uuid}, event_store}) do
    case State.issue_command(command, state) do
      {:ok, event} ->
        transaction = Lottery.EventStore.store(event_store, uuid, event)
        new_state = State.apply_event(event, state)
        {:reply, {:ok, transaction}, {new_state, event_store}}
      {:error, reason} ->
        {:reply, {:error, reason}, {state, event_store}}
    end
  end
end
