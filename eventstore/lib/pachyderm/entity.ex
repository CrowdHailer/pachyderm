defmodule Pachyderm.Entity do
  # The types could be struct. even if only described as map with key
  @type message :: any
  @type state :: any
  @type event :: any

  @callback execute(message, state) :: {:ok, [event]}
  @callback apply(event, state) :: state
end
