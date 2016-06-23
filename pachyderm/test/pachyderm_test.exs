defmodule FixedGenerator do
  def generate({FixedGenerator, id}) do
    id
  end
end

defmodule PachydermTest do
  use ExUnit.Case
  doctest Pachyderm

  alias VendingMachine.Command.{AddCoin, PushButton}

  test "the truth" do
    {:ok, ledger} = Pachyderm.Ledger.InMemory.start_link()
    {:ok, id} = VendingMachine.create(%{
      random: {FixedGenerator, 1234},
      ledger: {Pachyderm.Ledger.InMemory, ledger}
    })
    {:ok, entity} = Pachyderm.Entity.start_link(id, ledger)
    {:ok, state} = Pachyderm.Entity.instruct(entity, %AddCoin{})
    IO.inspect(state)
    {:ok, state} = Pachyderm.Entity.instruct(entity, %AddCoin{})
    IO.inspect(state)
    {:ok, state} = Pachyderm.Entity.instruct(entity, %PushButton{})

    # Read the ledger
    Pachyderm.Ledger.InMemory.inspect(ledger, self)
    receive do
      {:"$LedgerEntry", %{adjustments: adjustments}} ->
        Enum.each(adjustments, fn
          (%{entity: e, attribute: a, value: v, set: s}) ->
            IO.puts("#{e}, #{a}, #{v}, #{s}")
        end)
    end
    receive do
      {:"$LedgerEntry", %{adjustments: adjustments}} ->
        Enum.each(adjustments, fn
          (%{entity: e, attribute: a, value: v, set: s}) ->
            IO.puts("#{e}, #{a}, #{v}, #{s}")
        end)
    end
    receive do
      {:"$LedgerEntry", %{adjustments: adjustments}} ->
        Enum.each(adjustments, fn
          (%{entity: e, attribute: a, value: v, set: s}) ->
            IO.puts("#{e}, #{a}, #{v}, #{s}")
        end)
    end
  end
end
