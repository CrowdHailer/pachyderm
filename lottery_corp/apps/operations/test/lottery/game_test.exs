defmodule LotteryCorp.Operations.GameTest do
  use ExUnit.Case
  alias LotteryCorp.Operations.Game
  alias LotteryCorp.Operations.EventStore


  test "Game persists events to store" do
    uuid = :test
    {:ok, event_store} = EventStore.start_link()
    EventStore.monitor(event_store, self)
    {:ok, game} = Game.start_link(uuid, event_store)
    {:ok, _reaction} = Game.add_player(game, "Richard")
    assert_receive({:"$EntryPersisted", {1, ^uuid, adjustment}})
    assert {:added_player, "Richard"} = adjustment
  end

  test "Game reacts to events in store" do
    uuid = :test
    {:ok, event_store} = EventStore.start_link()
    # EventStore.monitor(event_store, self)
    {:ok, _id} = EventStore.persist(event_store, uuid, {:added_player, "Richard"})
    {:ok, game} = Game.start_link(uuid, event_store)
    {:ok, state} = Game.get_state(game)
    assert %{players: ["Richard"]} = state
    # assert_receive({:"$EntryPersisted", {1, ^uuid, adjustment}})
    # assert {:added_player, "Richard"} = adjustment
  end

  # test "Two references" do
  #   {:ok, event_store} = EventStore.start_link()
  #   EventStore.monitor(event_store, self)
  #   {:ok, jane} = Game.start_link(:jane, event_store)
  #   {:ok, harry} = Game.start_link(:harry, event_store)
  #   {:ok, _r} = Game.
  #   assert_receive({:"$EntryPersisted", {1, [adjustment]}})
  #   IO.inspect(adjustment)
  #   {:ok, _r} = Game.
  #   assert_receive({:"$EntryPersisted", {2, [adjustment]}})
  #   IO.inspect(adjustment)
  #   Process.exit(jane, :normal)
  #   {:ok, jane} = Game.start_link(:jane, event_store)
  #   :timer.sleep(100)
  #   {:ok, _r} = Game.
  #   assert_receive({:"$EntryPersisted", {3, []}})
  # end

  test "game" do
    {:ok, store} = EventStore.start_link([])
    {:ok, game} = Game.start_link(LotteryCorp.Operations.generate_game_key, store) # pass ev store/ start_link
    # These methods belong on a projection
    # assert :none == Game.winner(game)
    # assert [] == Game.players

    {:error, :no_players_to_win} = Game.pick_winner(game) # randomiser
    {:ok, _t} = Game.add_player(game, "Adam")
    {:ok, _t} = Game.add_player(game, "Bill")
    {:ok, _t} = Game.add_player(game, "Clive")
    {:ok, _t} = Game.add_player(game, "Clive")
    {:ok, _t} = Game.add_player(game, "Dan")
    {:ok, _t} = Game.remove_player(game, "Dan")
    {:ok, _t} = Game.remove_player(game, "Edward")
    {:ok, _t} = Game.pick_winner(game) # randomiser
    {:error, :lottery_closed} = Game.pick_winner(game) # randomiser
    {:error, :lottery_closed} = Game.add_player(game, "Fred")
    {:error, :lottery_closed} = Game.add_player(game, "George")
    # Put all events in a projection
    # TODO add time so that we can properly analyse
    # HAve event library take clock as dependency
  end
end
