defmodule Pachyderm.Entity do
  @moduledoc """
  A `Pachyderm.Entity` describes the behaviour of a durable actor.

  Implementations for `handle/2` and `update/2` must be provided.
  The `init/0` callback is optional, if not provided the initial state will be `nil`
  """

  # The types could be struct. even if only described as map with key
  @type message :: any
  @type state :: any
  @type event :: any

  @callback init() :: state
  @callback handle(message, state) :: {:ok, [event]}
  @callback update(event, state) :: state

  @optional_callbacks init: 0

  @doc false
  def initial_state(reference) do
    {module, _id} = reference

    case function_exported?(module, :init, 0) do
      true ->
        module.init()

      false ->
        nil
    end
  end

  @doc false
  def handle(reference, message, entity_state) do
    {module, _id} = reference

    case module.handle(message, entity_state) do
      {:ok, events} when is_list(events) ->
        {:ok, {events, []}}

      {:ok, {events, effects}} ->
        {:ok, {events, effects}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def reduce(reference, events) do
    reduce(reference, events, initial_state(reference))
  end

  def reduce(reference, events, initial_state) do
    {module, _id} = reference

    Enum.reduce(events, initial_state, fn event, state ->
      module.update(event, state)
    end)
  end
end
