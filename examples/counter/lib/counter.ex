defmodule Counter do
  use Pachyderm.Entity

  def init() do
    0
  end

  def activate(_request, state) do
    # state = state || 0
    state = state + 1
  end
end
