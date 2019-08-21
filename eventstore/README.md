# Pachyderm

**Safely implement actors as if they where the only one in existence.**

## Entities not Processes

The core computational unit in Pachyderm is an Entity.
These are also actors, i.e. they are a primitive of concurrent computation.

All messages handled by an entity see the up to date state of that actor.
The state history of an entity has a single well defined order.

An entity differs from a process because it can be stopped, restarted and moved between machines.

### Events as state primitive

The underlying storage required by Pachyderm is an append only log.
For this reason an event based API is exposed, rather than one based on the current state.

```elixir
def handle(message, state) do
  # ...
  {:ok, [event1, event2]}
end

def apply(event, state) do
  # ...
  new_state
end
```

It is possible to use this model for a state based system buy having all events be replace state events.

```elixir
def handle(message, state) do
  # ...
  {:ok, [replace_state_event]}
end

def apply(replace_state_event, _state) do
  # ...
  replace_state_event
end
```

### Globally unique events, NOT processes.

There may be more than one worker process alive for an entity at any given time.
This does not break any guarantees because a message is not considered handled by an entity until the events are committed to storage.
All storage backends must expose an optimistic concurrency control mechanism.

For efficiency purposes the library will reuse running workers for processing messages to a given entity.
This uses :global.
This is only to save starting processes, all the guarantees are handled at the storage layer.
This also means the library should work just as well in an unclustered environment.
However in this case it is possible that a worker for an entity gets started on every machine, so scaling machines wouldn't reduce load.

### Described side effects

All side effects from handling a message (message A) must happen after events are committed.
If the events fail to commit then the message (message B) that did create those events is the one that is considered handled at that point in time.
Message A is considered lost, if reliable delivery is required then retries and message acknowledgement can be layered on top
Most importantly side effects associated from handling message A must not exist, only those from handling message B

Side effects that should result from handling a message should be returned from the `handle` function.
Pachyderm will run this after successfully committing events.

```elixir
def handle(%SignUp{email: email}, state) do
  # ...
  events = %AccountCreated{email: email}
  effects = {MyApp.Mailer, %WelcomeEmail{email: email}}
  {:ok, {effects, events}}
end
```

Once events are committed, `MyApp.Mailer.dispach(message, config)` will be called.

It is up to the implementer to make sure no side effects happen in the `handle` function.
Elixir/erlang cannot guarantee that something has not been done.

I don't believe there is any harm in having a sidecause in the handle function,
such as generating a random number or getting the current date.
It may be easier to work with only pure functions, but I am not sure it is necessary (Needs further thought)

I consider all effects as a message to be sent somewhere, hence why the function on Mailer is called dispatch rather than run/execute

There are discussions of event vs message based systems online.
This is a message based approach, the event based approach would be to have sideeffects derrived from following the event log.

Both approaches have there guarantees.
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
Retries, timeouts and acknowledgement can all be tried on top.

It might be required to have a reliable timeout mechanism. (maybe not, needs further thought)
So when an entity is restarted any existing timers should be checked.

When writing to a database all events will be written in a single transaction.
That transaction could be left running until all the sideeffect handlers have run,
if these where to write to a task queue in the same transaction, then sideeffects would be reliably retryable.


Internal state working state activate/execute
