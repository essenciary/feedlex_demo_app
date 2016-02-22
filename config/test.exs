use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :feedlex_demo, FeedlexDemo.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :feedlex_demo, FeedlexDemo.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "docker",
  password: "docker",
  database: "feedlex_demo_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
