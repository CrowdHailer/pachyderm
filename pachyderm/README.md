# Pachyderm

**Event sourced actors for applications audit trail**

## Usage

### Single state counter

Define a state module for your entities.
```elixir
defmodule Counter.State do
  defstruct [id: nil, total: nil]
end

defimpl Pachyderm.Protocol, for: Counter.State do
  def instruct(%{id: id, total: current}, delta) when is_number(delta) do
    {:ok, [
      Pachyderm.Adjustment.unset(id, :total, current),
      Pachyderm.Adjustment.set(id, :total, current + delta)
    ]}
  end
end
```

From a Domin Driven Design perspective the creation of entities is normally due to the interaction of another entity. This means that we need to write code that will insert the creation events directly into the ledger.

```elixir
defmodule Counter do
  def creation(starting, id) do
    {:ok, [
      Pachyderm.Adjustment.set_state(id, State),
      Pachyderm.Adjustment.set(id, :total, starting)
    ]}
  end

  def create(starting \\ 0) do
    id = Pachyderm.generate_id()
    {:ok, adjustments} = creation(starting, id)
    {:ok, _record} = Pachyderm.Ledger.record(Pachyderm.Ledger, adjustments, :creation)
    {:ok, id}
  end
end
```

*An alternative to setting the total as part of the creation events would be to have the entity support a set value command/instruction.*

The counter is now available to be used.

```elixir
{:ok, counter1} = Counter.create
{:ok, state} = Pachyderm.Entity.instruct(counter1, 1)
{:ok, state} = Pachyderm.Entity.instruct(counter1, 1)
{:ok, counter2} = Counter.create
{:ok, state} = Pachyderm.Entity.instruct(counter2, 2)
{:ok, state} = Pachyderm.Entity.instruct(counter2, 2)
{:ok, state} = Pachyderm.Entity.instruct(counter1, -1)
{:ok, state} = Pachyderm.Entity.instruct(counter2, -2)
```

Finally we can see the list of all changes in the system

```elixir
{:ok, logs} = Pachyderm.Ledger.view_log()
IO.inspect(logs)
```

See this in action in the [example test file](https://github.com/CrowdHailer/event-sourcing.elixir/blob/master/pachyderm/examples/counter/test/counter_test.exs).

Pachyderm Supports event sourced finite statemachine using the unset_state and set_state adjustments.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add pachyderm to your list of dependencies in `mix.exs`:

        def deps do
          [{:pachyderm, "~> 0.0.1"}]
        end

  2. Ensure pachyderm is started before your application:

        def application do
          [applications: [:pachyderm]]
        end
