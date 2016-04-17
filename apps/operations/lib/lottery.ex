defmodule LotteryCorp.Operations do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(LotteryCorp.Operations.EventStore, [[name: LotteryCorp.Operations.EventStore]]),
      worker(LotteryCorp.Operations.Game.Supervisor, [[name: LotteryCorp.Operations.Game.Supervisor]]),
      worker(LotteryCorp.Operations.Game.Registry, [LotteryCorp.Operations.Game.Supervisor]),
    ]

    opts = [strategy: :one_for_one, name: LotteryCorp.Operations.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def create_game do
    ref = generate_game_key
    LotteryCorp.Operations.Game.Registry.lookup(LotteryCorp.Operations.Game.Registry, ref)
    {:ok, ref}
  end

  def add_player(ref, player) do
    {:ok, game} = LotteryCorp.Operations.Game.Registry.lookup(LotteryCorp.Operations.Game.Registry, ref)
    LotteryCorp.Operations.Game.add_player(game, player)
  end

  def remove_player(ref, player) do
    {:ok, game} = LotteryCorp.Operations.Game.Registry.lookup(LotteryCorp.Operations.Game.Registry, ref)
    LotteryCorp.Operations.Game.remove_player(game, player)
  end

  def pick_winner(ref) do
    {:ok, game} = LotteryCorp.Operations.Game.Registry.lookup(LotteryCorp.Operations.Game.Registry, ref)
    LotteryCorp.Operations.Game.pick_winner(game)
  end

  def get_game(id) do
    {:ok, game} = LotteryCorp.Operations.Game.Registry.lookup(LotteryCorp.Operations.Game.Registry, id)
    {:ok, state} = LotteryCorp.Operations.Game.get_state(game)
  end

  # http://stackoverflow.com/questions/32001606/how-to-generate-a-random-url-safe-string-with-elixir
  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  def generate_game_key do
    random_string(10)
  end
end
