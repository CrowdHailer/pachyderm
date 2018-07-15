# We can use swarm to start the process in individual manner
# It doesn't restart processes well so a replicated log is necessary
# Also need to externally save state.
# Can write to DB without event sourcing list of events to send
# Restarting the aggregate retries sendin
# Need the rebuilding kafka elixir forum topic

defmodule AggregateTest do
  use ExUnit.Case

  defmodule Lobby do
    use Pachyderm.Aggregate

    def init(_), do: []

    def handle({:wait, }, state) do
      %AssignedGame{id: id, }
    end

    def apply() do

    end
  end

  # Question around follow up events coming from handle or apply
  defmodule Game do
    use Pachyderm.Aggregate

    defevent PlayerMoved, name: "player_moved", specification: 2 do
      defstruct []

      def update() do

      end
    end

    def serialize_event do

    end


    def deseraialize_event(needs specification id) do
      # NOT symetric because requires spec id.

    end

    # EVENTS
    # PlayerMoved
    # PlayerMoved, GameWon/GameDrawn
  end


end
