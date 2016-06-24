defmodule Pachyderm.Ledger do
  @callback say_hello(String.t) :: any

  # adjustments -> entries
  # command -> meta
  def record(ledger, adjustments, command) do
    GenServer.call(ledger, {:record, adjustments, command})
  end

  def view_log(ledger \\ __MODULE__) do
    {:ok, t} = GenServer.call(ledger, {:inspect, self})
    logs = read_logs(t, [])
    {:ok, logs}
  end

  defp read_logs(t, total) do
    receive do
      {_, %{adjustments: adjusments, id: id}} ->
        case id == t do
          true -> total ++ adjusments
          false -> read_logs(t, total ++ adjusments)
        end
    end
  end

end
