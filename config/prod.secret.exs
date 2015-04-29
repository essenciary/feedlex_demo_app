use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :web_ui, WebUi.Endpoint,
  secret_key_base: "9z9Lnotq5dNg7AzRRwDfIzjLYXxJ99j2nkrhqb9vjCcrdDI+Lym8RpYseYhgLisP"

# Configure your database
config :web_ui, WebUi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "web_ui_prod"
