defmodule Game do
  defstruct id: 0, winner: :none
  def open do
    %__MODULE__{}
  end
end

defmodule LotteryTest do
  use ExUnit.Case
  doctest Lottery

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "Add player to game" do
    new_lottery = Game.open
    IO.inspect(new_lottery)
    state = []
    events = Lottery.issue_command(state, %Command.CreateGame{name: "Big Prizes"})
    {events, meta} = {[
      # {entity, attribute, value, transaction, learnt/unlearnt}
      {1, :"lottery/game", 1, 1, true},
      {2, :"game/name", "Big Prizes", 1, true}
    ], :stuff}

    # Simply concatinate the list of events
    state = Lottery.apply_events(state, events)
    {events, meta} = Lottery.issue_command(state, %Command.AddPlayer{game: 2, player: "Bob"})
    assert events == [
      {2, :"game/player", "Bob", 2, true}
    ]

    # Already added to the lottery
    # {:ok, transaction = {events, meta}}
    # {:error, %{command: c, error: ex}}
    {events, meta} = Lottery.issue_command(state, %Command.AddPlayer{game: 2, player: "Bob"})
    # Should be transaction 3
    assert events == []

    {:ok, {events, meta}} = Lottery.issue_command(state, %Command.DrawWinner{game: 2})
    assert events == [
      {2, :"game/winner", "Bob", 4, true}
    ]
  end
end
