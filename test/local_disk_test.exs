defmodule LocalDiskTest do
  use ExUnit.Case

  alias Pachyderm.Ecosystems.LocalDisk, as: Eco

  # defmodule Worker do
  #   use GenServer
  #
  #   def start_link(ecosystem_id, entity_id) do
  #     name = via_tuple(ecosystem_id, entity_id)
  #     GenServer.start_link(__MODULE__, {ecosystem_id, entity_id}, name: name)
  #   end
  #
  #   defp via_tuple(ecosystem_id, entity_id) do
  #     {:via, Registry, {ecosystem_id, entity_id}}
  #   end
  # end

  defmodule Counter do
    use Pachyderm.Entity

    def init(_entity_id), do: 0
    def activate(_message, state), do: {[], state + 1}
  end

  test "foo" do
    # Registry.start_link(:unique, :foo)
    # |> IO.inspect()
    #
    # Registry.start_link(:unique, :foo)
    # |> IO.inspect()
    #
    # Worker.start_link(:foo, {A, :b})
    # |> IO.inspect()
    #
    # Worker.start_link(:foo, {A, :b})
    # |> IO.inspect()


    Eco.follow({Counter, "a"})
    |> IO.inspect
    Eco.send_sync({Counter, "a"}, 5)
    |> IO.inspect
    Eco.send_sync({Counter, "a"}, 5)
    |> IO.inspect

    assert_receive {{LocalDiskTest.Counter, "a"}, _}
    assert_receive {{LocalDiskTest.Counter, "a"}, _}
    refute_receive {{LocalDiskTest.Counter, "a"}, _}

    Eco.send_sync({Counter, "a"}, :kill)
    |> IO.inspect

    # Subscription should last restarts
    Eco.send_sync({Counter, "a"}, 5)
    |> IO.inspect
    assert_receive {{LocalDiskTest.Counter, "a"}, :x}

    # {:ok, ref} = :dets.open_file(:a, [file: 'pachyderm.ets', type: :set])
    # |> IO.inspect
    # k = {make_ref(), {IO, "23"}}
    # :dets.lookup(:a, k)
    # |> IO.inspect
    # :dets.insert(:a, {k, 5})
    # :dets.insert(:a, {k, 7})
    # |> IO.inspect
    # :dets.lookup(:a, k)
    # |> IO.inspect
    # |> IO.inspect
    # :dets.open_file(:foo, file: ")
    # |> IO.inspect
    # :dets.all()
    # |> IO.inspect
    # :dets.open_file(:foo, file: ")
    # :dets.init_table(:a, fn(x) -> IO.inspect(x) end)
  end
end
