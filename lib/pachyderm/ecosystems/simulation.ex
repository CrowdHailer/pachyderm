defmodule Pachyderm.Ecosystems.Simulation do
  @moduledoc """
  rename cohort simulation
  Implementation of an `Ecosystem` as a single data structure.

  This is useful for tests although some semantics have changed.

  - A call to apply message/stimulus to the system will return only after all messages have been resolved.
    Most other backends return once the message has been accepted

  ## TODO
  - Needs a limit to number of messages it will process.
    This can just be implemented as a check against the length of processed.
  - Debug tools

    - Just raise error if anything fails, can't see history of state.
    - keep map of errors. Can take the list of commands
    - keep list of all event's applied against an entity. Filter to those just sent to the entity
    - Group by the list of events. and count duplications for how common it is to get into that situation.
    - write unit test for the entity

    - With property testing can try duplications.
    - given a fixed size piece of random can guarantee size
    - Need to say that all states are contained in some end state.
  """

  # processed = handled
  defstruct [:entities, :processed, :errors]

  def fresh() do
    %__MODULE__{entities: %{}, processed: []}
  end

  # separate to run and do_run
  # run accepts options such processed limit and fail on exception
  def run(envelopes, ecosystem \\ fresh())
  def run([], ecosystem) do
    ecosystem
  end
  def run(envelopes, ecosystem) do
    {remaining, ecosystem} = step(envelopes, ecosystem)
    run(remaining, ecosystem)
  end
  def run_all do

  end
  def run_cohort(_message, _world, _seed) do

  end

  def step([{address, message} | remaining_messages], ecosystem) do
    {new_messages, new_ecosystem} = activate(ecosystem, address, message)
    {remaining_messages ++ new_messages, new_ecosystem}
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

  # can make a pop all combos function
  # Then property testing can just pick selection
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
