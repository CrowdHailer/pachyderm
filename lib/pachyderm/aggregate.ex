defmodule Incremented do
  use Pachyderm.Event, type: "increment", revision: 2

  def update(1, :inc) do
    {:inc, 1}
  end
end

# aggregate_id could be stream_id
defmodule Pachyderm.Aggregate do
  # episodic time
end
