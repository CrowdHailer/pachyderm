defmodule FixedGenerator do
  def generate({FixedGenerator, id}) do
    id
  end
end

defmodule PachydermTest do
  use ExUnit.Case
  doctest Pachyderm

  alias VendingMachine.Command.{AddCoin, PushButton}

  test "with a registry" do
    {:ok, ledger} = Pachyderm.Ledger.InMemory.start_link()

    {:ok, adjustments} = VendingMachine.creation("some-id")
    {:ok, adjustments2} = VendingMachine.creation("some-other-id")
    {:ok, transaction} = Pachyderm.Ledger.InMemory.record(ledger, adjustments ++ adjustments2, {:creation, :id})
    # Have each entity as a pid so lookup logic can be handled slowely
    {:ok, supervisor} = Pachyderm.Entity.Supervisor.start_link()
    {:ok, entity} = Pachyderm.Entity.Supervisor.start_child(supervisor, ["some-id", ledger])
    {:error, {:already_started, ^entity}} = Pachyderm.Entity.Supervisor.start_child(supervisor, ["some-id", ledger])
    {:ok, entity} = Pachyderm.Entity.Supervisor.start_child(supervisor, ["some-other-id", ledger])
    # {:error, "no memory of bad uuid"} = Pachyderm.Registry.find(:bad_uuid)
    # {:ok, entity} = Pachyderm.Registry.find(:uuid)
    {:ok, state} = Pachyderm.Entity.instruct(entity, %AddCoin{})
    IO.inspect(state)
  end

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
