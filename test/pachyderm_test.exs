defmodule PachydermTest do
  use ExUnit.Case
  doctest Pachyderm

  defmodule Counter do
    use Pachyderm.Entity

    def init(), do: 0
    def activate(message, state), do: state + 1
  end

  test "state is preserved between activations" do
    id = {Counter, "a"}
    assert = {:ok, 1} = Pachyderm.activate(id, :increment)
    assert = {:ok, 2} = Pachyderm.activate(id, :increment)
  end

  test "state is independent between entities" do
    b = {Counter, "b"}
    c = {Counter, "c"}
    assert = {:ok, 1} = Pachyderm.activate(b, :increment)
    assert = {:ok, 1} = Pachyderm.activate(c, :increment)
  end

  # kind must implement entity
  # raising error must keep state
  # multi-node killing agent must keep state
end
