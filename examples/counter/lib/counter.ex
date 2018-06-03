defmodule Counter do
  # use Pachyderm.Entity

  def init() do
    0
  end

  def execute(_request, state) do
    # state = state || 0
    state = state + 1
  end
end
