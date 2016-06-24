defmodule Counter do
  def creation(starting, id) do
    {:ok, [
      Pachyderm.Adjustment.set_state(id, Counter.State),
      Pachyderm.Adjustment.set(id, :total, starting)
    ]}
  end

  def create(starting \\ 0) do
    id = Pachyderm.generate_id()
    {:ok, adjustments} = creation(starting, id)
    {:ok, _record} = Pachyderm.Ledger.record(Pachyderm.Ledger, adjustments, :creation)
    {:ok, id}
  end

  def add_value(counter, amount) do
    Pachyderm.Entity.instruct(counter, amount)
  end
end
