defmodule LotteryCorp.Operations.GameTest do
  use ExUnit.Case
  alias LotteryCorp.Operations.Game


  @tag :skip
  test "game" do
    {:ok, store} = LotteryCorp.Operations.EventStore.start_link([])
    {:ok, game} = Game.start_link(LotteryCorp.Operations.generate_game_key, store) # pass ev store/ start_link
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
    # Put all events in a projection
    # TODO add time so that we can properly analyse
    # HAve event library take clock as dependency
  end
end
