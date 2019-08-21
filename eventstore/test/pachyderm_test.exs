defmodule PachydermTest do
  use ExUnit.Case
  doctest Pachyderm

  test "greets the world" do
    assert Pachyderm.hello() == :world
  end
end
