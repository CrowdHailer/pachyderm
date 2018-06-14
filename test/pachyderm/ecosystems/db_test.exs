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
    # I think the system should manange with only ecosystem_sup
    {:ok, ecosystem: %{supervisor: ecosystem_sup, id: ecosystem_id}}
  end

  test "state is preserved after processing each message", %{ecosystem: ecosystem} do
    my_counter = {Counter, "my_counter"}
    assert :ok = PgBacked.send_sync(my_counter, :increment, ecosystem)
    assert :ok = PgBacked.send_sync(my_counter, :increment, ecosystem)
    Process.sleep(10_000)
  end

  def random_string() do
    length = 12
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
