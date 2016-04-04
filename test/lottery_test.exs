defmodule LotteryTest do
  use ExUnit.Case
  # doctest LotteryCorp

  test "Add player to game" do
    {:ok, game_id} = Lottery.create_game()
    Lottery.add_player(game_id, "Mick")
    # Lottery.add_player(make_ref, "Adam")
  end


  # Test the game registry
  # - when it creates a game then the number of children on the game supervisor should go up by one
  # - it should register under its module name in global
  # - it should return the same pid after registering(this is only requrement as addind to supervisor is incidental)
  #  - Added to supervisor is not with the intention of restarting
  # - registry needs to call event store with name
  # - spinning up a game if there is no initial event should fail
end
