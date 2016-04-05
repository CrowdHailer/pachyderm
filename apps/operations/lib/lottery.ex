defmodule LotteryCorp.Operations do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(LotteryCorp.Operations.EventStore, [[name: LotteryCorp.Operations.EventStore]]),
      worker(LotteryCorp.Operations.Game.Supervisor, [[name: LotteryCorp.Operations.Game.Supervisor]]),
      worker(LotteryCorp.Operations.Game.Registry, []),
    ]

    opts = [strategy: :one_for_one, name: LotteryCorp.Operations.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def create_game do
    ref = make_ref
    {:ok, pid} = LotteryCorp.Operations.Game.Supervisor.start_game(LotteryCorp.Operations.Game.Supervisor)
    :global.register_name(ref, pid)
    {:ok, ref}
  end

  def add_player(ref, player) do
    pid = :global.whereis_name(ref)
    LotteryCorp.Operations.Game.add_player(pid, player)
  end
end
