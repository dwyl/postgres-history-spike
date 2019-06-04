use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :require_history, RequireHistoryWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :require_history, RequireHistory.Repo,
  username: "postgres",
  password: "postgres",
  database: "require_history_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
