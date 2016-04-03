defmodule GameTest do
  use ExUnit.Case
  defmodule Game do
    defmodule State do
      defstruct winner: :none, players: []
    end
    defmodule Command do
      defmodule AddPlayer do
        defstruct player: ""
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

    def init(:new_state) do
      # needs to set up an agregate id with event store
      {:ok, %Game.State{}}
    end
    def handle_call({:add_player, player}, _from, s = %{winner: :none, players: players}) do
      state = %{s | players: players}
      {:reply, {:ok, :transaction}, state}
    end
  end

  test "game" do
    {:ok, game} = Game.start_link # pass ev store/ start_link
    # These methods belong on a projection
    # assert :none == Game.winner(game)
    # assert [] == Game.players

    {:ok, transaction_id} = Game.add_player(game, "Bill")
    IO.inspect transaction_id
    events = Game.add_player(game, "Dan")
    events = Game.add_player(game, "Dan")
    events = Game.remove_player(game, "Bill")
    events = Game.pick_winner(game) # randomiser
  end
end
