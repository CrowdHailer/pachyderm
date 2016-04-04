defmodule Lottery do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Lottery.EventStore, [[name: Lottery.EventStore]]),
      worker(Lottery.Game.Supervisor, [[name: Lottery.Game.Supervisor]]),
      worker(Lottery.Game.Registry, []),
    ]

    opts = [strategy: :one_for_one, name: Lottery.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def create_game do
    ref = make_ref
    {:ok, pid} = Lottery.Game.Supervisor.start_game(Lottery.Game.Supervisor)
    :global.register_name(ref, pid)
    {:ok, ref}
  end

  def add_player(ref, player) do
    pid = :global.whereis_name(ref)
    Lottery.Game.add_player(pid, player)
  end
end
