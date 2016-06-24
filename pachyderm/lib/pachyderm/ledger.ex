defmodule Pachyderm.Ledger do
  @callback say_hello(String.t) :: any

  # adjustments -> entries
  # command -> meta
  def record(ledger, adjustments, command) do
    GenServer.call(ledger, {:record, adjustments, command})
  end

end
