# Pachyderm - an elephant never forgets

**A virtual/immortal/durable/resilient/global actor "always exists" and "never fails".**

Program with actors that are durable and globally unique "in effect".
Pachyderm calls an actor with these properties an entity.

Entities are useful where there are strong consistency requirements.
They also mitigate several of the [problems with Single Global Processes](https://keathley.io/blog/sgp.html).

This idea was loosely inspired by projects like [Microsoft Orleans](https://dotnet.github.io/orleans/).

Further explanation can be found in the [Design notes](#design-notes).

## Usage

### Defining an Entity

```elixir
defmodule MyApp.Counter do
  @behaviour Pachyderm.Entity

  alias MyApp.Counter.{Increment, ...}
  alias MyApp.Counter.{Increased, ...}

  def init() do
    %{count: 0}
  end

  def handle(%Increment{}, _state) do
    events = [%Increased{amount: 1}]
    {:ok, events}
  end

  def update(%Increased{amount: amount}, state = %{count: current}) do
    %{state | count: current + amount}
  end
end
```

*In event sourcing execute/apply would be the equivalent terms to handle/update.*

Both the `handle/2` and `update/2` callbacks MUST NOT create any side effects, see [Entity side effects](#entity-side-effects) for how to create side effects.

### Sending messages to an Entity

```elixir
type = MyApp.Counter
id = UUID.uuid4()
reference = {type, id}

{:ok, state} = Pachyderm.call(reference, %Increment{})
# => {:ok, %{count: 1}}
```

*The id of an entity MUST be uuid that is unique across all entities, regardless of type.*

### Entity side effects

An entity creates side effects by, optionally, returning a list of effects in addition to the the list of events.
Pachyderm dispatches effects once the events have be committed to storage.

```elixir
defmodule MyApp.Counter do
  def handle(%Increment{}, %{count: count}) do
    events = [%Increased{amount: 1}]

    if count == 9 do
      effects = [{MyApp.AdminMailer, %{threshold: 10}}]
      {:ok, {events, effects}}
    else
      {:ok, events}
    end
  end
end
```

Side effects have at most once semantics. This is because the events are committed before dispatching effects and it is always possible for the dispatch to fail/crash.

*A future feature should allow persisting effects to a task queue in the same transaction as events are committed.*

```elixir
defmodule MyApp.AdminMailer do
  @behaviour Pachyderm.Effect

  @admin_email "admin@myapp.example"

  def dispatch(%{threshold: threshold}, _config) do
    body = "The threshold was reached at a count of #{threshold}"

    EmailProvider.send(@admin_email, body)
  end
end
```

*The config value can be passed as a third argument to `Pachyderm.send`.*


## Testing

```
docker-compose up
mix do event_store.drop, event_store.create, event_store.init
mix test
```

## Design notes

### Entities vs Processes

The core computational unit in Pachyderm is an Entity.

Entities, like processes are actors, i.e. they are a primitive of concurrent computation.
- All messages handled by an entity see the latest state of that entity.
- The state history of an entity has a single, well defined order.

An entity differs from a process because it can be restarted and moved between machines.

### Events as state primitive

The underlying storage required by Pachyderm is an append only log.
For this reason an event based API is exposed, rather than one based on the current state.

It is possible to use this model for a state based system by having all events be replace state events.
For the counter example this could look like.

```elixir
def handle(%Increment{}, %{count: current}) do
  events = [%NewCount{value: current + 1}]
  {:ok, events}
end

def update(%NewCount{value: new_count}, _state) do
  %{count: new_count}
end
```

The library chooses to use actor terminology over event sourcing. e.g. handle vs execute.

### Globally unique events, NOT processes.

There may be more than one worker process alive for an entity at any given time.
This does not break any guarantees because a message is not considered handled by an entity until the events are committed to storage.
**All storage backends must expose an optimistic concurrency control mechanism.**

Processing messages for a given entity will be handled by running workers where possible.
Workers are registered using `:global`.

Worker registration is only to save starting processes, all the guarantees are handled at the storage layer.
This also means the library should work just as well in an unclustered environment.

Note in an unclustered setup, it is possible that a worker for an entity gets started on every machine.
In such a case scaling the number of machines wouldn't reduce load.

### Deferred side effects

All side effects from handling a message must happen after events are committed.

For example.
- Two messages (message A) and (message B) are processed concurrently, potentially on two node that cannot communicate.
- The events from one message (message A) are committed to storage successfully.
- Events from the other message (message B) cannot be saved, as these events were calculated from a stale entity state.
- **Side effects from handling message B must not exist, only the effects from handling message A**
- Message B is considered lost, if reliable delivery is required then retries and message acknowledgement can be layered on top

The Pachyderm effects API exists to allow Entities to interact with other parts of the system in a safe manner.

It is up to the developer to make sure no side effects happen in the `handle` function.
Elixir/erlang cannot enforce this.

##### Question

I don't believe there is any harm in having a sidecause in the handle function,
such as generating a random number or getting the current date.
It may be easier to work with only pure functions, but I am not sure it is necessary (Needs further thought)

##### Message vs Event Based

I consider all effects as a message to be sent somewhere, hence why the function on Mailer is called dispatch rather than run/execute

There are discussions of event vs message based systems online.
This is a message based approach, the event based approach would be to have sideeffects derrived from following the event log.

Both approaches have there advantages.
- Message based moves more logic into the entity (it would have existed in subscribers in an event system)
  This allows more of an application to be tested at a pure level inside the entity functions.
- Message based is more aligned with the erlang process model for familiarity
- Event based subscriptions have the added complexity of requiring a durable cursor for progress they have made through the event log
- Event based writes everything to storage, a problem if the event should trigger sending an email with one time code that can't be saved in DB
- Message based is more likely to be at most once, event based at least once. Messages can be lost, vs subscription cursor failing to be updated. Probably this is not a hard and fast separating, see sideeffect guarantees and subscription cursor could be updated before processing effect.

It is easier to build at least once delivery on top of at most once delivery.
It also might be possible to have both by adding the ability to subscribe to an event log in addition to the effects API described here.
Effect could also be to write to "all" stream and have no default ability to follow an entity.

### SideEffect guarantees

There is no guarantee that a side effect will run successfully, the real world does that.
If side effects are considered as messages out then it is always possible they can be lost.

This is also fine the actor model makes no guarantees about message delivery.
Retries, timeouts and acknowledgement can all be layered on top.

It might be required to have a reliable timeout mechanism. (maybe not, needs further thought)
So when an entity is restarted any existing timers should be checked.
Process

When writing to a database all events will be written in a single transaction.
That transaction could be left running until all the sideeffect handlers have run,
if these where to write to a task queue in the same transaction, then sideeffects would be reliably retryable.

### Use Entity references as side effects

It would be easy to return `{reference, message}` from a handle function.
The assumption here is that the dispatch action should be to send the message to the referred to entity.

This has not been done yet. I am unsure if there is a sensible default for retrying to send the message/task durability
Perhaps it would work if there could be exactly once semantics by marking the task as done in the same transaction as the receiving entity receives events.

Tasks that crash should be marked as crashed for a specific version of the module, if it changes they should automatically be retried.

### Sync Snapshots for Entity lookup

There should be a way of committing snapshot/query module in the same transaction
Currently this is entity_state but could be working_state

### Entity references

All entities can be addressed by their reference, this is a combination of type and id.

This was the most pragmatic approach, when starting out it is intuitive to ascribe types to entities.
One of the problems with entity types is that entities last forever and so the concept of type might evolve overtime.

It is possible to have a system with only one type of entity and have the event history fully describes the state of an entity including it's type.
This is however unwieldy, the behaviour for all entity types ends up in a single callback module.

Consideration of this issue is why entities are uniquely identified by their id only.
It allows systems to evolve.
Entities that were created from one module can be, in the systems future, handled by multiple modules.
For example the `User` module could evolve to `LegacyUser` and `NewUser` depending on which API endpoints are used to interact with the system.

Performance also improves by limiting entity id's to `uuid4` only.

### Return/Reply values

There are two options for this

#### Result return values

```
{:ok, [event]}
{:ok, {[event], [effect]}}
{:error, reason}
```
- Limits options, potentially a good thing.
- Makes it clear that returning an error value to a caller means no events were created.

#### GenServer inspired reply values

```
{:reply, {:ok, anything}, [event]}
{:reply, {:ok, anything}, [event], [effect]}
{:reply, {:error, reason}, [], []}
```
- Can have error response and no events. Good/Bad?
- Reply often based on the state, state not calculated until after update function called, often end up working things out twice.
- Add another tuple argument for continuations/timeout. Might be very ugly in OK case

#### Sending full state as part of reply value

The simplest API is to have the new state returned when sending a message to an entity.

Sending the full state back is wasteful if it, is large, is not needed, is transferred between machines.
An explicit reply can be set in `handle` but what if clients sending the same update what different views.

To reduce the amount sent there could be a Query API where an anonymous function is sent and only that result returned.
This separates logic from the entity and so a :query callback might be better. clients just send a simple/expected query and the result is generated from that.

If on separate nodes you might not want to send message then query, requiring some kind of message then query interface
If sending only a reduced value back the new cursor (stream_version) is probably the most useful. It allows a client to listen for all events.

To reduce messages between nodes could have a cache process on every node, queries only go to local, commands are sent via local which waits for event before running query and returning to caller.
A follower on every node messes up scaling, more node doesn't increase free up memory.
Also it doesn't really match a dist erl environment.
My assumption is extra nodes are added for more memory, latency of sending messages between nodes is not important.
Probably if latency is a problem, the best option is sticky sessions so normal lookup from Pachyderm results in intra node communicate in most cases.

I think we should stick with the simple for a while, most of the issues are for high performace cases.

### Can Worker inactivity timeouts be a global setting?

A system where all entities can be active could have no timeouts, entities only restarted on deploy.
In reality I think an entity is likely to know when it is no longer going to be activated. However even these cases might have the end state queried for some time.

There should be a Stop event that caches final snapshot.

### Should it be possible to have effects without events?

I can't think of any good thing that will come out of this, it basically just skips all checks.

### Should calculated state be one of the arguments to effect dispatch?

This is another place where state can be worked out twice, in dispatch and update

### Non global address space using network_id

It would be good to start more than one `EntitySupervisor` and have separate interacting environments (ecosystems) of entities.
One way to handle this would be to have a network_id id column in EventStore and have all interaction with the DB scoped to a specific network_id.
Different network identifier should be able to use different pools/db connections.

In a global network of entities, creating a reference could take the environment as an argument so giving separate id's.
This is rather reliant on the developer doing the right thing repetitavly.  

## TODO

- If waiting on specific promises, entity MUST terminate if nothing to await on.

- Single global process, some discussion on this, is it a safe way to have single global processes?

https://yiming.dev/blog/2019/08/16/use-return-value-to-defer-decisions/

Old stuff https://github.com/CrowdHailer/pachyderm/commit/bd852b376e58c318183a60f1b8ddf18ada1fe6cc

- Counter using Protocols
  - Linked all events created to the command that created them. command id being the transaction and idempotency id is a possibility
  - Can do protocols with a Global entity module. Implement protocol on null struct to handle create messages
  - Implement protocol on others for each state.
  - Most things don't change that much so it's a lot of struct typing for little benefit, shows that everything can be types but has not checking of those types
- Pachyderm/Pachyderm
  - Trying to implement set/unset adjustments, maybe makes it easier to query but too much overhead, reimplimenting datomic
- Top level
  - Pessimistic lock by taking DB lock, lock can be lost while processing continues. see forum discussion. https://elixirforum.com/t/an-experimental-implementation-of-actors-that-do-not-die/14608/11
  - Ecosystem seems passable name for grouping of entities though.
  - Check ecosystems exhaust function for walk through, lot's of notes
