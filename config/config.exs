use Mix.Config

default_db_name =
  if function_exported?(Mix, :env, 0) do
    "eventstore_#{Mix.env()}"
  else
    "eventstore_dev"
  end

config :eventstore, column_data_type: "jsonb"

config :eventstore, EventStore.Storage,
  serializer: EventStore.JsonbSerializer,
  types: EventStore.PostgresTypes,
  hostname: System.get_env("EVENTSTORE_PG_HOST") || "localhost",
  username: System.get_env("EVENTSTORE_PG_USER") || "elmer",
  password: System.get_env("EVENTSTORE_PG_PASS") || "patchwork",
  database: System.get_env("EVENTSTORE_PG_DB") || default_db_name,
  pool_size: 10,
  pool_overflow: 5
