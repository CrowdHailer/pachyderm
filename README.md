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
