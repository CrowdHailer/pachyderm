defmodule Pachyderm.Ecosystems.Simulation do
  @moduledoc """
  rename cohort simulation
  Implementation of an `Ecosystem` as a single data structure.

  This is useful for tests although some semantics have changed.

  - A call to apply message/stimulus to the system will return only after all messages have been resolved.
    Most other backends return once the message has been accepted
  """

  # processed = handled
  defstruct [:entities, :processed, :errors]

  def fresh() do
    %__MODULE__{entities: %{}, processed: []}
  end

  def reduce([], world) do
    world
  end

  def reduce([{label, message} | rest], world) do
    {new_messages, new_world} = activate(world, label, message)
    reduce(rest ++ new_messages, new_world)
  end

  def exhaust([], world) do
    world
  end

  def exhaust(messages, world) do
    for i <- 0..(length(messages) - 1) do
      Task.async(fn ->
        {{label, message}, rest} = List.pop_at(messages, i)
        {new_messages, new_world} = activate(world, label, message)
        exhaust(rest ++ new_messages, new_world)
      end)
    end
    |> Enum.map(&Task.await/1)
    |> List.flatten()
  end

  def activate(world, {kind, id}, message) do
    state = get_entity(world, kind, id)
    {messages, new_state} = kind.activate(message, state)
    new_world = put_entity(world, kind, id, new_state)
    processed = new_world.processed ++ [{{kind, id}, message}]
    {messages, %{new_world | processed: processed}}
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
