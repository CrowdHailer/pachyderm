defmodule PachydermTest do
  use ExUnit.Case
  doctest Pachyderm

  defmodule Counter do
    use Pachyderm.Entity

    def init(), do: 0
    def activate(:increment, state), do: state + 1
  end

  test "state is preserved between activations" do
    id = {Counter, "a"}
    assert {:ok, 1} = Pachyderm.activate(id, :increment)
    assert {:ok, 2} = Pachyderm.activate(id, :increment)
  end

  test "state is independent between entities" do
    b = {Counter, "b"}
    c = {Counter, "c"}
    assert {:ok, 1} = Pachyderm.activate(b, :increment)
    assert {:ok, 1} = Pachyderm.activate(c, :increment)
  end

  test "state updates are sent to followers" do
    d = {Counter, "d"}
    assert {:ok, 0} = Pachyderm.follow(d)
    assert {:ok, 1} = Pachyderm.activate(d, :increment)
    assert_receive {^d, 1}
  end

  # kind must implement entity
  # raising error must keep state
  # multi-node killing agent must keep state
end
