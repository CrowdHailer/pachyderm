defmodule PingPongTest do
  use ExUnit.Case
  alias Pachyderm.Ecosystems.LocalMachine, as: Eco

  test "participation in the same ecosystem gives same references" do
    ref = make_ref()
    assert Eco.participate(ref) == Eco.participate(ref)
  end

  defmodule Server do
    use Pachyderm.Entity

    def init(id), do: :waiting
    def activate({:ping, client}, :waiting) do
      {[{client, :pong}], :pinged}
    end
  end

  defmodule Client do
    use Pachyderm.Entity

    def init(id), do: :waiting
    def activate(:pong, :waiting) do
      {[], :ponged}
    end

  end

  test "ping pong" do
    eco = Eco.participate()
    server_id = :rand.uniform(1_000_000)
    server = {Server, server_id}
    assert {:ok, :waiting} = Eco.follow(server, eco)
    client_id = :rand.uniform(1_000_000)
    client = {Client, client_id}
    assert {:ok, :pinged} = Eco.send_sync(server, {:ping, client}, eco)
    assert {:ok, :ponged} = Eco.follow(client, eco)
  end
end
