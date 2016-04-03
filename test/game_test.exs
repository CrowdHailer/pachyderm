defmodule GameTest do
  use ExUnit.Case
  defmodule Game do
    defmodule State do
      defstruct winner: :none, players: []
      def issue_command({:add_player, player}, %{players: players, winner: :none}) do
        case Enum.member?(players, player) do
          true -> {:ok, []}
          false -> {:ok, [{:added_player, player}]}
        end
      end
      def issue_command({:remove_player, player}, %{players: players, winner: :none}) do
        case Enum.member?(players, player) do
          true -> {:ok, [{:removed_player, player}]}
          false -> {:ok, []}
        end
      end
      def issue_command({:pick_winner, _seed}, %{players: []}) do
        {:error, :no_players_to_win}
      end
      def issue_command({:pick_winner, _seed}, %{players: players, winner: :none}) do
        winner = Enum.random(players)
        {:ok, [{:picked_winner, winner}]}
      end
      def issue_command(command, %{winner: winner}) do
        {:error, :lottery_closed}
      end

      def apply_events([event | rest], state) do
        new_state = apply_event(event, state)
        apply_events(rest, new_state)
      end
      def apply_events([], state) do
        {:ok, state}
      end

      def apply_event(event = {:added_player, player}, state = %{players: players}) do
        IO.inspect(event)
        %{state | players: players ++ [player]}
      end
      def apply_event(event = {:removed_player, player}, state = %{players: players}) do
        IO.inspect(event)
        %{state | players: Enum.filter(players, fn(p) -> p != player end)}
      end
      def apply_event(event = {:picked_winner, winner}, state = %{winner: :none}) do
        IO.inspect(event)
        %{state | winner: winner}
      end
    end
    use GenServer

    def start_link do
      # Should be game id
      GenServer.start_link(__MODULE__, :new_state)
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

    def init(:new_state) do
      # needs to set up an agregate id with event store
      {:ok, %Game.State{}}
    end

    def handle_call(command, from = {pid, _ref}, state) do
      case State.issue_command(command, state) do
        {:ok, events} ->
          send(pid, events)
          # {:ok, transaction_id} = EventStore.store(events)
          {:ok, new_state} = State.apply_events(events, state)
          {:reply, {:ok, :transaction_id}, new_state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end
  end

  test "game" do
    {:ok, game} = Game.start_link # pass ev store/ start_link
    # These methods belong on a projection
    # assert :none == Game.winner(game)
    # assert [] == Game.players

    {:error, reason} = Game.pick_winner(game) # randomiser
    IO.inspect reason
    {:ok, _t} = Game.add_player(game, "Adam")
    {:ok, _t} = Game.add_player(game, "Bill")
    {:ok, _t} = Game.add_player(game, "Clive")
    {:ok, _t} = Game.add_player(game, "Clive")
    {:ok, _t} = Game.add_player(game, "Dan")
    {:ok, _t} = Game.remove_player(game, "Dan")
    {:ok, _t} = Game.remove_player(game, "Edward")
    {:ok, _t} = Game.pick_winner(game) # randomiser
    {:error, reason} = Game.pick_winner(game) # randomiser
    IO.inspect reason
    {:error, reason} = Game.add_player(game, "Fred")
    IO.inspect reason
    {:error, reason} = Game.add_player(game, "George")
    IO.inspect reason
    receive do
      e -> IO.inspect(e)
    end
    # Put all events in a projection
    # TODO add time so that we can properly analyse
    # HAve event library take clock as dependency
  end
end
