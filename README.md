# pachyderm - an elephant never forgets

```elixir
defmodule MyApp.Counter do
  use Pachyderm.Entity

  def init(), do: 0
  def activate(message, state), do: state + 1
end
  # Or activate trigger
  # react proceed
  # Or message
```

# Notes
- Like whatthehook except
  - custom code in source and not pushed by client, no js execution
- Don't use `self()` inside an agent callbacks, it will change.
- Default behaviour for init is to return `nil`.
- At the moment if Pachyderm.Agent dies then state is lost. That is awkward
- id == {kind, label}
- following handles by :pg2 so all usecases of process exiting etc are handled

# Roadmap

- Add Counter.id(entity_id) -> default {module, entity_id}
  - can be overwritten to check type of id
  - return opaque types Counter.activate(entity_id, allowed messages)
- register across nodes using global
- return better values based on errors
- secondary actions by returning list of {type, id, message}
- idempotentency concerns
- pass contexts around for better testing
- Sharded or ets backed supervisor for performance
- Rename Counter.send calls Counter.handle
- Event sourcing
  - requires ability to return separate event to updated state

## Below some old notes on Event sourcing I am keeping around

# Event Sourcing in Elixir

https://www.youtube.com/watch?v=fQPsTEgd48I
https://www.youtube.com/watch?v=R2Aa4PivG0g

https://tech.zilverline.com/2012/07/23/simple-event-sourcing-consistency-part-2

Experiments with eventsourced implementations in elixir.

### Opinions

- Commands don't always produce the same events for a given state, Side effects can occur.
- State must always be the same for a given application of state and event.
- Events are undeniable event application cannot fail so event handle cant have side effects.
- Entities should never exist in invalid states so sould be sent events grouped by transaction.
- An uninitialised state should always accept a creation event therefore we can skip a creation command and directly add creation event to the store

### Counter using Protocols
An event sourced counter with the follow features.
- In memory ledger of events
- State rebuilding of counter from ledger history
- Multi event handling. (1 command can produce multiple events.)
- Supercharged counting state dispatched using elixir protocols

### Lottery Corp
First example, builds entities on top of GenServer

- [Motivational talk for modelling time properly](https://www.youtube.com/watch?v=Nhz5jMXS8gE)
- [Acid 2.0](https://lostechies.com/jimmybogard/2013/06/06/acid-2-0-in-action/)
- [Bloom project](http://boom.cs.berkeley.edu/)
-

https://www.youtube.com/watch?v=66bU45vVF00 talk on bloom


task based UI is a good argument for CQRS and/or event systems

https://cqrs.wordpress.com/documents/task-based-ui/
virtual-strategy.com/2014/11/20/utilizing-task-driven-ui-create-high-performing-and-scalable-business-software/
http://www.uxmatters.com/mt/archives/2014/12/task-driven-user-interfaces.php
