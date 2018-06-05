defmodule JankenTest do
  use ExUnit.Case

  defmodule Lobby do
    def init(_), do: []

    def activate({:start_game, player_a, player_b}, state) do
      game_id = length(state) + 1
      invite = {:invite, {JankenTest.Game, game_id}}

      messages = [
        {player_a, invite},
        {player_b, invite}
      ]

      new_state = [{game_id, player_a, player_b} | state]
      {messages, new_state}
    end
  end

  defmodule Game do
    defstruct [:first, :second]
    def init(_), do: %__MODULE__{}

    def activate({:move, player_a, move_a}, %__MODULE__{first: nil}) do
      messages = [{player_a, :waiting_for_opponent}]
      new_state = %__MODULE__{first: {player_a, move_a}}
      {messages, new_state}
    end

    def activate({:move, player_b, move_b}, state = %__MODULE__{first: {player_a, _move_a}}) do
      new_state = %{state | second: {player_b, move_b}}
      result = resolve(new_state)

      messages = [
        {player_a, result},
        {player_b, result}
      ]

      {messages, new_state}
    end

    defp resolve(%{first: {_pa, m}, second: {_pb, m}}), do: :draw
    defp resolve(%{first: {pa, :rock}, second: {_pb, :scissors}}), do: {:winner, pa}
    defp resolve(%{first: {pa, :scissors}, second: {_pb, :paper}}), do: {:winner, pa}
    defp resolve(%{first: {pa, :paper}, second: {_pb, :rock}}), do: {:winner, pa}
    defp resolve(%{first: {_pa, _}, second: {pb, _}}), do: {:winner, pb}
  end

  defmodule Player do
    def init(id), do: id

    def activate({:invite, game}, "alice") do
      self = {Player, "alice"}
      {[{game, {:move, self, :paper}}], "alice"}
    end
    def activate({:invite, game}, "bob") do
      self = {Player, "bob"}
      {[{game, {:move, self, :rock}}], "bob"}
    end
    def activate(:waiting_for_opponent, id) do
      {[], id}
    end
    # Just ignore result messages for now
    def activate(_, id) do
      {[], id}
    end
  end

  defmodule World do
    defstruct [:entities, :messages, :errors]
    def fresh() do
      %__MODULE__{entities: %{}}
    end

    def activate(world, {kind, id}, message) do
      # IO.inspect(message)
      state = get_entity(world, kind, id)
      {messages, new_state} = kind.activate(message, state)
      new_world = put_entity(world, kind, id, new_state)
      {messages, new_world}
    end

    defp get_entity(world, kind, id) do
      get_in(world.entities, [kind, id]) || kind.init(id)
    end
    defp put_entity(world, kind, id, state) do
      entities = Map.put_new(world.entities, kind, %{})
      new_entities = put_in(entities, [kind, id], state)
      %{world | entities: new_entities}
    end
  end

  # label/address/channel = {kind, id}
  def step({[{label, message} | rest], world}) do
    new_messages = World.activate(world, label, message)
    {rest ++ new_messages, world}
  end

  def reduce([], world) do
    world
  end
  def reduce([{label, message} | rest], world) do
    {new_messages, new_world} = World.activate(world, label, message)
    reduce(rest ++ new_messages, new_world)
  end

  test "" do
    lobby = {Lobby, "lobby"}
    alice = {Player, "alice"}
    bob = {Player, "bob"}
    initial_world = World.fresh()
    first_messages = [{lobby, {:start_game, alice, bob}}]
    reduce(first_messages, initial_world)
  end
end
