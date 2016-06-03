defmodule LotteryCorp.Operations.Game.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_game(supervisor, game_id) do
    Supervisor.start_child(supervisor, [game_id, LotteryCorp.Operations.EventStore])
  end

  def init(:ok) do
    # Note the args passed to worker spec are appended with args added as superviror start args
    children = [
      worker(LotteryCorp.Operations.Game, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
