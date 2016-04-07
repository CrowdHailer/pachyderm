defmodule LotteryCorp.Operations.Game.StateTest do
  use ExUnit.Case
  alias LotteryCorp.Operations.Game.State

  test "initial state should have no Players" do
    assert %State{players: []} = State.init(:game_id)
  end

  test "initial state should have Game id" do
    game_id = :game_id
    assert %State{uuid: ^game_id} = State.init(game_id)
  end

  test "initial state should not have a winner" do
    assert %State{winner: :none} = State.init(:game_id)
  end
end
