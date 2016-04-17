defmodule LotteryCorp.Operations do
  use Application

  alias LotteryCorp.Operations.{Game, EventStore}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(EventStore, [[name: EventStore]]),
      worker(Game.Supervisor, [[name: Game.Supervisor]]),
      worker(Game.Registry, [Game.Supervisor]),
    ]

    opts = [strategy: :one_for_one, name: LotteryCorp.Operations.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def create_game do
    ref = generate_game_key
    Game.Registry.lookup(Game.Registry, ref)
    {:ok, ref}
  end

  def add_player(ref, player) do
    {:ok, game} = Game.Registry.lookup(Game.Registry, ref)
    Game.add_player(game, player)
  end

  def remove_player(ref, player) do
    {:ok, game} = Game.Registry.lookup(Game.Registry, ref)
    Game.remove_player(game, player)
  end

  def pick_winner(ref) do
    {:ok, game} = Game.Registry.lookup(Game.Registry, ref)
    Game.pick_winner(game)
  end

  def get_game(id) do
    {:ok, game} = Game.Registry.lookup(Game.Registry, id)
    {:ok, state} = Game.get_state(game)
  end

  # http://stackoverflow.com/questions/32001606/how-to-generate-a-random-url-safe-string-with-elixir
  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  def generate_game_key do
    random_string(10)
  end
end
