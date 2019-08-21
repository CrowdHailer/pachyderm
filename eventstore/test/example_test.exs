defmodule ExampleTest do
  use ExUnit.Case

  test "counter integration" do
    {:ok, supervisor} =
      DynamicSupervisor.start_link(
        strategy: :one_for_one,
        extra_arguments: [%{test: self()}]
      )

    first_counter = UUID.uuid4()
    assert {:ok, %{count: 1}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert {:ok, %{count: 2}} = Pachyderm.deliver(supervisor, first_counter, :increment)

    # Make a function called pull that has a max and requires you to pull the next, no state in server.
    # Would a pain if sync so would probable want to send a subscribed message then event, would require state
    assert {:ok, 2} = Pachyderm.follow(supervisor, first_counter, 0)
    # Need to revceive them with counter/cursor number and stream id {Entity module, id}
    # TEST old events are sent to the follower
    assert_receive {:events,
                    [%Example.Counter.Increased{amount: 1}, %Example.Counter.Increased{amount: 1}]}

    # TEST new events are sent to the follower
    assert {:ok, %{count: 3}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}

    assert {:ok, %{count: 4}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}
    refute_receive _

    assert {:ok, %{count: 5}} = Pachyderm.deliver(supervisor, first_counter, :increment)
    assert_receive {:events, [%Example.Counter.Increased{amount: 1}]}
    assert_receive %{alert: 5}

    other_counter = UUID.uuid4()
    assert {:ok, %{count: 1}} = Pachyderm.deliver(supervisor, other_counter, :increment)

    pid = :global.whereis_name(first_counter)

    :ok = DynamicSupervisor.terminate_child(supervisor, pid)

    assert {:ok, %{count: 6}} = Pachyderm.deliver(supervisor, first_counter, :increment)
  end
end
