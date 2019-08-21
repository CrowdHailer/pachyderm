defmodule ExampleTest do
  use ExUnit.Case

  # Better name than dispatch -> execute point out is sync
  test "counter integration" do
    # TODO start with Dynamic Supervisor, config
    # TODO separate event saving, retries, or potentially just on the client. might have moved on
    counter_id = "01"
    assert {:ok, %{count: 1}} = Pachyderm.dispatch(counter_id, :increment)
    assert {:ok, %{count: 2}} = Pachyderm.dispatch(counter_id, :increment)

    # Make a function called pull that has a max and requires you to pull the next, no state in server.
    # Would a pain if sync so would probable want to send a subscribed message then event, would require state
    assert {:ok, 2} = Pachyderm.follow(counter_id, 0)
    # Need to revceive them with counter/cursor number and stream id {Entity module, id}
    # TEST old events are sent to the follower
    assert_receive {:events, [%{increased: 1}, %{increased: 1}]}

    # TEST new events are sent to the follower
    assert {:ok, %{count: 3}} = Pachyderm.dispatch(counter_id, :increment)
    assert_receive {:events, [%{increased: 1}]}

    assert {:ok, %{count: 4}} = Pachyderm.dispatch(counter_id, :increment)
    assert_receive {:events, [%{increased: 1}]}
    refute_receive _

    assert {:ok, %{count: 5}} = Pachyderm.dispatch(counter_id, :increment)
    assert_receive {:events, [%{increased: 1}]}
    assert_receive 5
    # TODO testing the store
  end
end
