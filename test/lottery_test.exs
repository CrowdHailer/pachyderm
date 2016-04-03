
defmodule LotteryCorp do
  def list_games(%{games: games}) do
    games
  end

  def new_game(_state, name: name) do
    {:ok, {
      [{1, :"game/name", name, true}],
      %{transaction: 1}}
    }
  end

  defmodule State do
    defstruct games: []
    def apply_events(state, []) do
      state
    end
    def apply_events(state, [event | tail]) do
      new_state = apply_event(state, event)
      apply_events(new_state, tail)
    end

    def apply_event(state, {_entity, :"game/name", name, true}) do
      game = LotteryCorp.Game.create(name)
      %{state | games: state.games ++ [game]}
    end
  end

  defmodule Game do
    defstruct id: 0, winner: :none, name: "", players: []
    def create(name) do
      %__MODULE__{name: name}
    end

    def name(%__MODULE__{name: name}) do
      name
    end
    def winner(%__MODULE__{winner: winner}) do
      winner
    end
    def players(%__MODULE__{players: players}) do
      players
    end
  end
end

defmodule LotteryTest do
  use ExUnit.Case
  # doctest LotteryCorp

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "Add player to game" do
    state = %LotteryCorp.State{}
    assert [] == LotteryCorp.list_games(state)
    {:ok, {events, _meta}} = LotteryCorp.new_game(state, name: "Big Prizes")
    # To be replaced with an apply events function so the knowledge that it is an array is hidden
    state = LotteryCorp.State.apply_events(state, events)
    [game] = LotteryCorp.list_games(state)
    assert "Big Prizes" == LotteryCorp.Game.name(game)
    :none = LotteryCorp.Game.winner(game)
    [] = LotteryCorp.Game.players(game)
    # assert on game

    # {:ok, {events, _meta}} = LotteryCorp.add_player(state, game: game, player: "Bob")
    # # If using actor shouldn't need to respond with transaction??
    # :accepted = LotteryCorp.add_player(actor, game: game, player: "Bob")
    # # {:denied, reason}
    # # Passing in the first state should be a config step.
    # # It should be possibe to have a globally registered process that represents
    # :accepted = LotteryCorp.add_player(game: game, player: "Bob")
    # # Second event creates no events
    # :accepted = LotteryCorp.add_player(game: game, player: "Bob")
    #
    # :accepted = LotteryCorp.draw_winner(game: game)
    # {:failed, {reason, command}} = LotteryCorp.add_player(game: game, player: "Bob")

    # events = LotteryCorp.issue_command(state, %Command.CreateGame{name: "Big Prizes"})
    # {events, meta} = {[
    #   # {entity, attribute, value, transaction, learnt/unlearnt}
    #   # Probably not needed
    #   {1, :"lottery/game", 1, 1, true},
    #   {2, :"game/name", "Big Prizes", 1, true}
    # ], :stuff}
    #
    # # Simply concatinate the list of events
    # state = LotteryCorp.apply_events(state, events)
    # {events, meta} = LotteryCorp.issue_command(state, %Command.AddPlayer{game: 2, player: "Bob"})
    # assert events == [
    #   {2, :"game/player", "Bob", 2, true}
    # ]
    #
    # # Already added to the lottery
    # # {:ok, transaction = {events, meta}}
    # # {:error, %{command: c, error: ex}}
    # {events, meta} = LotteryCorp.issue_command(state, %Command.AddPlayer{game: 2, player: "Bob"})
    # # Should be transaction 3
    # assert events == []
    #
    # {:ok, {events, meta}} = LotteryCorp.issue_command(state, %Command.DrawWinner{game: 2})
    # assert events == [
    #   {2, :"game/winner", "Bob", 4, true}
    # ]
  end
end
