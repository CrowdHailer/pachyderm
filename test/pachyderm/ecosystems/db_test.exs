defmodule Pachyderm.Ecosystems.DBTest do
  use ExUnit.Case

  alias Pachyderm.Ecosystems.PgBacked

  defmodule Counter do
    use Pachyderm.Entity

    def init(_entity_id), do: 0
    def handle(_message, state), do: {[], state + 1}
  end

  setup %{} do
    ecosystem_id = random_string()
    {:ok, ecosystem_sup} = PgBacked.start_link(ecosystem_id)
    {:ok, ecosystem: %{supervisor: ecosystem_sup, id: ecosystem_id}}
  end

  test "state is preserved after processing each message", %{ecosystem: ecosystem} do
    id = {Counter, "my_counter"}
    assert :ok = PgBacked.send_sync(id, :increment, ecosystem)
    assert {:ok, 2} = PgBacked.send_sync(id, :increment, ecosystem)
    Process.sleep(10_000)
  end

  @tag :skip
  test "taking out locks" do
    hostname = "localhost"
    username = "elmer"
    password = "patchwork"
    {:ok, session1} = Postgrex.start_link(hostname: hostname, username: username, password: password, database: "elmer")
    |> IO.inspect
    Postgrex.query(session1, "SELECT 1", [])
    |> IO.inspect
    Postgrex.query(session1, "SELECT pg_advisory_lock(1, 1)", [])
    |> IO.inspect
    Postgrex.query(session1, "SELECT pg_advisory_lock(1, 1)", [])
    |> IO.inspect
    {:ok, session2} = Postgrex.start_link(hostname: hostname, username: username, password: password, database: "elmer")
    |> IO.inspect
    # Postgrex.query(session2, "SELECT pg_advisory_lock(1, 1)", [], [timeout: 500])
    # |> IO.inspect

    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)
    # Name it via Ecosystem
    DynamicSupervisor.start_child(supervisor, %{id: MyWorker, start: {MyWorker, :start_link, [[name: {:via, Singleton, {%{pg_session: session1}, MyWorker, 45}}]]}})
    |> IO.inspect
    DynamicSupervisor.start_child(supervisor, %{id: MyWorker, start: {MyWorker, :start_link, [[name: {:via, Singleton, {%{pg_session: session2}, MyWorker, 45}}]]}})
    |> IO.inspect

    :erlang.phash2({A, 2}, :math.pow(2, 32) |> round)
    |> IO.inspect
    :erlang.phash2({B, 2}, :math.pow(2, 32) |> round)
    |> IO.inspect
  end

  def random_string() do
    length = 12
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
