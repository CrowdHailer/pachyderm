# Event Sourcing in Elixir

Experiments with eventsourced implementations in elixir.

### Counter using Protocols
An event sourced counter with the follow features.
- In memory ledger of events
- State rebuilding of counter from ledger history
- Multi event handling. (1 command can produce multiple events.)
- Supercharged counting state dispatched using elixir protocols

### Lottery Corp
First example, builds entities on top of GenServer
