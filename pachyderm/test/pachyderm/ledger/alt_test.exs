defmodule Pachyderm.Ledger.AltTest do
  use ExUnit.Case, async: true
  alias Pachyderm.Ledger

  test "Entries recorded in the ledger have increasing id" do
    {:ok, ledger} = Ledger.Alt.start_link
    {:ok, %{id: first}} = Ledger.record(ledger, :change1, :command)
    {:ok, %{id: second}} = Ledger.record(ledger, :change2, :command)
    assert second > first
  end
end
