# Pachyderm - an elephant never forgets

**Immortal actors for many machines.**

```elixir
defmodule MyApp.Counter do
  use Pachyderm.Entity

  def init(), do: 0
  def activate(_message, state), do: state + 1
end
```

*`init/0` is optional, default implementation returns `nil`.*

```elixir
$ iex -S mix

iex> counter = {Counter, "my_counter"}
# {Counter, "my_counter"}
iex> Pachyderm.activate(counter, :increment)
# {:ok, 1}
iex> Pachyderm.activate(counter, :increment)
# {:ok, 2}

iex> Pachyderm.follow(counter)
# {:ok, 2}
iex> Pachyderm.activate(counter, :increment)
# {:ok, 3}
iex> flush()
# {{Counter, "my_counter"}, 3}
# :ok
```

## Notes

### Consistency / Availability / Partition Tolerance

Pachyderm chooses consistency at all costs within an entity.
Within an entity all activations are guaranteed to be run with latest state.

The combination of `{module, term}` is an entities id.
Only a single entity can be running at any time.

**NOTE: The scope of this guarantee of uniqueness depends on the backend being used.
The default backend for development purposes guarantees this for one node ONLY.**

Make configuring or starting a backend a requirement

### Immortal entities

If an activation fails during exectution, the entity can still be reactivated we the previous persisted state. Followers of an entity will continue to receive updates.

An entity should not make use of `self()` as it will change between activations.

### Actor model

Because sending a message to an entity will automatically create it;
Pachyderm reduces the possible actions of an actor to only two kinds.

1. Sending a message.
2. Updating your own state.

### Prior Art

- whatthehook
  - custom code is pushed by client and is JavaScript so this project has lots of things aroung vm/execution
- Orleans/Erleans

### Events vs State

Event based is a lower abstraction because you can always have the event state_replaced

# Explination

```
fn activate(msg, s0) -> {msgs, s1}
```
Add `init` and namespacing by type for convenience.
Can always use a single type if think this is not necessary as well as default

# Outside world

Observation only by looking at state of entities.
Easy to push in new messages. Just interupt with approprite new message
or take existing world and start executing.
Outside can watch and act. e.g. Have a payments to make actor.
This is pulled off by an outside worker that adds messages when done.
If we have at least once delivery we can just retry until done
Test env might want to emulate retries

# Different implementation

e.g. a timer in the Simulation environment can return immidiatly
Needs some switch out modules.

## First article

Simple functional view is extended with init

In rust can we prove purity if we take ownership and destroy?

# examples

sharded usernamer registrar.
Can read state which is the same as having subscribed

# Roadmap

At the moment if the agent shadowing an entity dies then the entity state is lost.
This is fine for local development but not many other usecases

### DB backed backend

This will require the ability to plugin/configure backends.

By using `:global` + locks on the DB, uniqueness of activations can be guaranteed across nodes.
Steps to running an activation.

1. See if the entity is already running in `:global`.
2. Take out advisory lock for entity, if this fails retry search in global.
3. Register new instantiation of entity in `:global`.

### File storage for local backend

### Partition on Username registration

Because id can be generated no that the id responsible for Bob is "bo".
`Pachyderm.activate({UsernameRegistration, "bo"}, {:register, "bob", {User, "32123132112"}})`
Have a streaming listener on every node that acts as a cache.

writes are not blocked because partitioning. reads do not hit the writers because of streaming.
The immortal actor world view is then very nice.
Talk at Elixir London meets
This is probably the best motivation for an ability to send diffs. i.e. events.

### Separated idea of passive active entities
The idea of an active entity is it will be automatically restarted on another machine.
And not just in response to a to an external message.

### Event sourced entites
Have the ability to save and send only deltas/events and build a working state each time the entity is started

### Other notes

- configure type of agent, globally or part of context/world/space/workspace.
- add switch to use file storage for local/single node. Can down an up so practise upgrades
- write history of events to file
- It's like a work queue only results are committed not tasks/commands
- Add Counter.id(entity_id) -> default {module, entity_id}
  - can be overwritten to check type of id
  - return opaque types Counter.activate(entity_id, allowed messages)
- register across nodes using global
- return better values based on errors
- secondary actions by returning list of {type, id, message}
- idempotentency concerns, just use a map set or similar. not optimising for performance right now, or use optimistic concurrency lock keys.
- pass contexts around for better testing
- Sharded or ets backed supervisor for performance
- Rename Counter.send calls Counter.handle
- Event sourcing
  - requires ability to return separate event to updated state
- use `make_ref()` at compile time to ensure nodes are running the same types.

- names for activate
  - Or activate trigger handle
  - react proceed
  - Or message
- can remove task and do everything inside a process

## Below some old comments on Event sourcing I am keeping around

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
