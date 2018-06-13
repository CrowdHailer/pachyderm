defmodule Pachyderm.Ecosystems.DBTest do
  use ExUnit.Case

  defmodule MyWorker do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, [], opts)
    end
  end

  defmodule Singleton do
    @spec whereis_name(integer) :: pid() | :undefined

    def whereis_name({_, _, id}) when is_integer(id) do
      :global.whereis_name(id)
    end

    def register_name({%{pg_session: pg_session}, _, id}, pid) do
      case lock(pg_session, id) do
        :yes ->
          :global.register_name(id, pid)
        :no ->
          :no
      end
    end

    defp lock(pg_session, entiy_id) do
      Postgrex.query!(pg_session, "SELECT pg_advisory_lock(1, $1)", [entiy_id], [timeout: 500])
      :yes
    rescue
      e in DBConnection.ConnectionError ->
        :no
    end
  end

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
end
