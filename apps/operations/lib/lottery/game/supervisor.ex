defmodule LotteryCorp.Operations.Game.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_game(supervisor, game_id) do
    Supervisor.start_child(supervisor, [LotteryCorp.Operations.EventStore])
  end

  def init(:ok) do
    children = [
      worker(LotteryCorp.Operations.Game, [:uuid], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
