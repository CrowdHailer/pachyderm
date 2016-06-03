# Counter

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add counter to your list of dependencies in `mix.exs`:

        def deps do
          [{:counter, "~> 0.0.1"}]
        end

  2. Ensure counter is started before your application:

        def application do
          [applications: [:counter]]
        end


possible way to handle starting multiple different types of actors
```elixir
defmodule Uninitialized do
  defstruct []
end
defimpl GenSourced, for: Uninitialized do
  def handle_command(_state, command) do
    raise "Cant accept commands"
  end
  def handle_event(_state, snapshot) do
    snapshot
  end
end
```
