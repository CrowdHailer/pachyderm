defmodule Lottery do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Lottery.EventStore, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lottery.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def create_game do
    ref = make_ref
    {:ok, pid} = Lottery.Game.start_link(ref)
    :global.register_name(ref, pid)
    {:ok, ref}
  end

  def add_player(ref, player) do
    pid = :global.whereis_name(ref)
    Lottery.Game.add_player(pid, player)
  end
end
