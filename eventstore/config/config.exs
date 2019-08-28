use Mix.Config

config :eventstore, column_data_type: "jsonb"

config :eventstore, EventStore.Storage,
  serializer: EventStore.JsonbSerializer,
  types: EventStore.PostgresTypes,
  username: "elmer",
  password: "patchwork",
  database: "eventstore_dev",
  hostname: "localhost",
  pool_size: 10,
  pool_overflow: 5
