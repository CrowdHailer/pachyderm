defmodule JankenTest do
  use ExUnit.Case

  defmodule Lobby do
    def init(_), do: []

    def activate({:start_game, player_a, player_b}, state) do
      game_id = length(state) + 1
      invite = {:invite, {JankenTest.Game, game_id}}

      messages = [{player_a, invite}, {player_b, invite}]

      new_state = [{game_id, player_a, player_b} | state]
      {messages, new_state}
    end
  end

  defmodule GameOld do
    defstruct [:first, :second]
    def init(_), do: %__MODULE__{}

    def activate({:move, player_a, move_a}, %__MODULE__{first: nil}) do
      messages = [{player_a, :waiting_for_opponent}]
      new_state = %__MODULE__{first: {player_a, move_a}}
      {messages, new_state}
    end

    def activate({:move, player_b, move_b}, state = %__MODULE__{}) do
      new_state = %{state | second: {player_b, move_b}}
      result = resolve(new_state)
      {[], result}
    end

    defp resolve(%{first: {_pa, m}, second: {_pb, m}}), do: :draw
    defp resolve(%{first: {pa, :rock}, second: {_pb, :scissors}}), do: {:winner, pa}
    defp resolve(%{first: {pa, :scissors}, second: {_pb, :paper}}), do: {:winner, pa}
    defp resolve(%{first: {pa, :paper}, second: {_pb, :rock}}), do: {:winner, pa}
    defp resolve(%{first: {_pa, _}, second: {pb, _}}), do: {:winner, pb}
  end

  defmodule Game do
    def init(_), do: nil

    def activate({:move, player_a, move_a}, nil) do
      messages = [{player_a, :waiting_for_opponent}]
      new_state = {:waiting, player_a, move_a}
      {messages, new_state}
    end

    def activate({:move, player_b, move_b}, {:waiting, player_a, move_a}) do
      new_state = resolve({player_a, move_a}, {player_b, move_b})
      {[], new_state}
    end

    defp resolve({pa, m}, {pb, m}), do: {:draw, pa, pb}
    defp resolve({pa, :rock}, {pb, :scissors}), do: {:win, pa, pb}
    defp resolve({pa, :scissors}, {pb, :paper}), do: {:win, pa, pb}
    defp resolve({pa, :paper}, {pb, :rock}), do: {:win, pa, pb}
    defp resolve({pa, _}, {pb, _}), do: {:win, pb, pa}
  end

  defmodule Player do
    def init(id), do: id

    def activate({:invite, game}, state), do: {[{game, move(state)}], state}
    def activate(_, id), do: {[], id}

    defp move("alice"), do: {:move, {Player, "alice"}, :paper}
    defp move("bob"), do: {:move, {Player, "bob"}, :rock}
  end

  # 1 * 2 * 2 * 2 * 3 * 2 * 1
  test "simple test to reduce whole space" do
    lobby = {Lobby, "lobby"}
    alice = {Player, "alice"}
    bob = {Player, "bob"}
    initial_world = Pachyderm.Ecosystems.Simulation.fresh()
    first_messages = [{lobby, {:start_game, alice, bob}}]

    assert [_] = Pachyderm.Ecosystems.Simulation.exhaust(first_messages, initial_world)
    |> Enum.reduce(%{}, fn world, acc ->
      Map.update(acc, world.entities, world.processed, &[world.processed | &1])
    end)
    |> Map.keys()
    # |> IO.inspect()

    # Show the number of combinations
    # show that there are two worlds
    # rewrite to {:waiting, player}
    # rewrite to {:win, player_a, player_b}
  end

  # Can write a test case that the list of all messages is equal to all combinations/
end
