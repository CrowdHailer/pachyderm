defmodule LocalDiskTest do
  use ExUnit.Case
  alias Pachyderm.Ecosystems.LocalDisk

  defmodule Counter do
    use Pachyderm.Entity

    def init(_entity_id), do: 0
    def activate(_message, state), do: {[], state + 1}
  end

  setup %{} do
    ecosystem = LocalDisk.participate(random_string())
    {:ok, ecosystem: ecosystem}
  end

  test "state is preserved between activations", %{ecosystem: ecosystem} do
    id = {Counter, "my_counter"}
    assert {:ok, 1} = LocalDisk.send_sync(id, :increment, ecosystem)
    assert {:ok, 2} = LocalDisk.send_sync(id, :increment, ecosystem)
  end

  test "state is independent between entities", %{ecosystem: ecosystem} do
    my_counter = {Counter, "my_counter"}
    other_counter = {Counter, "other_counter"}
    assert {:ok, 1} = LocalDisk.send_sync(my_counter, :increment, ecosystem)
    assert {:ok, 1} = LocalDisk.send_sync(other_counter, :increment, ecosystem)
  end

  test "state updates are sent to followers", %{ecosystem: ecosystem} do
    my_counter = {Counter, "my_counter"}
    assert {:ok, 0} = LocalDisk.follow(my_counter, ecosystem)
    assert {:ok, 1} = LocalDisk.send_sync(my_counter, :increment, ecosystem)
    assert_receive {^my_counter, 1}
  end

  defmodule PingPong do
    use Pachyderm.Entity

    def activate({:ping, client}, nil), do: {[{client, :pong}], :pinged}
    def activate(:pong, nil), do: {[], :ponged}
  end

  test "envelopes are forwarded to entities", %{ecosystem: ecosystem} do
    alice = {PingPong, "alice"}
    bob = {PingPong, "bob"}
    assert {:ok, nil} = LocalDisk.follow(alice, ecosystem)
    assert {:ok, nil} = LocalDisk.follow(bob, ecosystem)

    # Alice pings Bob
    assert {:ok, :pinged} = LocalDisk.send_sync(bob, {:ping, alice}, ecosystem)
    assert_receive {^bob, :pinged}
    assert_receive {^alice, :ponged}
  end

  # TODO test that activations and follower are isolated between environments
  # TODO test that crashes leave old state intacted
  # TODO test what happens when an init fails, possibly add check to assert behaviour has been given.

  def random_string() do
    length = 12
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
