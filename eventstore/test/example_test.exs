defmodule ExampleTest do
  use ExUnit.Case

  test "counter integration" do
    {:ok, supervisor} = Pachyderm.EntitySupervisor.start_link(%{test: self()})

    first_counter = Example.Counter.new_address()
    :ok = EventStore.subscribe(elem(first_counter, 1) |> IO.inspect(), mapper: & &1.data)
    # :ok = EventStore.subscribe(elem(first_counter, 1) |> IO.inspect())
    Process.sleep(1500)
    assert {:ok, %{count: 1}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert {:ok, %{count: 2}} = Pachyderm.deliver(supervisor, first_counter, :increment)

    # Make a function called pull that has a max and requires you to pull the next, no state in server.
    # Would a pain if sync so would probable want to send a subscribed message then event, would require state
    # assert {:ok, 2} = Pachyderm.follow(supervisor, first_counter, 0)
    # Need to revceive them with counter/cursor number and stream id {Entity module, id}
    # TEST old events are sent to the follower
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}

    # TEST new events are sent to the follower
    assert {:ok, %{count: 3}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}

    assert {:ok, %{count: 4}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}
    refute_receive _

    assert {:ok, %{count: 5}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}
    assert_receive %{alert: 5}

    other_counter = Example.Counter.new_address()
    assert {:ok, %{count: 1}} = Pachyderm.deliver(supervisor, other_counter, :increment)

    pid = :global.whereis_name(first_counter)

    :ok = DynamicSupervisor.terminate_child(supervisor, pid)

    assert {:ok, %{count: 6}} = Pachyderm.deliver(supervisor, first_counter, :increment)

    # refute_receive _
    # assert {:ok, 6} = Pachyderm.follow(supervisor, first_counter, 0)
    assert_receive {:events, events}
    # assert length(events) == 6

    # TEST event appended elsewhere
    Pachyderm.Log.append(first_counter, 6, [%Example.Counter.Increased{amount: 1}])

    # Need to resubscribe and wait for this because other wise we can dispatch the event too quickly
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}
    # Follower is lost because we killed the process earlier
    assert {:ok, %{count: 8}} = Pachyderm.deliver(supervisor, first_counter, :increment)
  end
end
