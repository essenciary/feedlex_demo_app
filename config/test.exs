use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_ui, WebUi.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :web_ui, WebUi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "web_ui_test",
  size: 1,
  max_overflow: false
