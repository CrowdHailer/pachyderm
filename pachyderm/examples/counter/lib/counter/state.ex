defmodule Counter.State do
  defstruct [id: nil, total: nil]
end

defimpl Pachyderm.Protocol, for: Counter.State do
  def instruct(%{id: id, total: current}, delta) when is_number(delta) do
    {:ok, [
      Pachyderm.Adjustment.unset(id, :total, current),
      Pachyderm.Adjustment.set(id, :total, current + delta)
    ]}
  end
end
