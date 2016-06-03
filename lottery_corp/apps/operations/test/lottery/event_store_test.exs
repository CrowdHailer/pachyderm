defmodule LotteryCorp.Operations.EventStoreTest do
  use ExUnit.Case
  alias LotteryCorp.Operations.EventStore

  # FIXME only follow single channel
  # The channel will simply be the lottery id
  test "appending values " do
    {:ok, event_store} = EventStore.start_link
    channel = :test
    {:ok, first} = EventStore.persist(event_store, channel, :change1)
    {:ok, second} = EventStore.persist(event_store, channel, :change2)
    assert second > first
  end

  test "Will send history to new follower" do
    {:ok, event_store} = EventStore.start_link
    channel = :test
    {:ok, first} = EventStore.persist(event_store, channel, change = :change)
    EventStore.follow(event_store, self)
    assert_receive({_, {^first, ^channel, ^change}})
  end

  test "Will send new messages to follower" do
    {:ok, event_store} = EventStore.start_link
    channel = :test
    EventStore.follow(event_store, self)
    {:ok, first} = EventStore.persist(event_store, channel, change_1 = :change_1)
    assert_receive({_, {^first, ^channel, ^change_1}})
    {:ok, second} = EventStore.persist(event_store, channel, change_2 = :change_2)
    assert_receive({_, {^second, ^channel, ^change_2}})
  end

  test "Can observe to get new entries only" do
    {:ok, event_store} = EventStore.start_link
    channel = :test
    {:ok, first} = EventStore.persist(event_store, channel, change_1 = :change_1)
    EventStore.monitor(event_store, self)
    refute_receive({_, {^first, ^channel, ^change_1}})
    {:ok, second} = EventStore.persist(event_store, channel, change_2 = :change_2)
    assert_receive({_, {^second, ^channel, ^change_2}})
  end
end
