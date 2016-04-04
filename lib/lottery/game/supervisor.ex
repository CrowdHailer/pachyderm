defmodule Lottery.Game.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_game(supervisor) do
    Supervisor.start_child(supervisor, [Lottery.EventStore])
  end

  def init(:ok) do
    children = [
      worker(Lottery.Game, [:uuid], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
