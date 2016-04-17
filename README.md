# LotteryCorp

**Experiments with CQRS**

f(state, command) -> [events...]
f(state, [events]) -> new_state

A lottery has
- Id
- many participants
- possible a winner


Invarients for property testing.

- number of participants should always be 1 greater after command to add participant
- participant should always be in the list after being added

### Lessons
- Naming is really hard. Not just thinking up names but also sharing. Name are really a self identity(uuid) and a number of listings with other entities.
- A Ledger/store is a Queue not a stack.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add lottery to your list of dependencies in `mix.exs`:

        def deps do
          [{:lottery, "~> 0.0.1"}]
        end

  2. Ensure lottery is started before your application:

        def application do
          [applications: [:lottery]]
        end
