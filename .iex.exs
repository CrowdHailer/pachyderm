alias Pachyderm.Ecosystems.PgBacked

defmodule Counter do
  use Pachyderm.Entity

  def init(_entity_id), do: 0
  def handle(_message, state), do: {[], state + 1}
end

my_counter = {Counter, "my_counter"}
