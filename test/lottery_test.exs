defmodule LotteryTest do
  use ExUnit.Case
  # doctest LotteryCorp

  test "Add player to game" do
    {:ok, game_id} = Lottery.create_game()
    Lottery.add_player(game_id, "Mick")
    # Lottery.add_player(make_ref, "Adam")
  end
end
