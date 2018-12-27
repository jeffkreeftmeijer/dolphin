# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :dolphin, DolphinWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DfbJtT3ioLu1ynRkZKNozJls7e8DoFnWg7R7noBlOqyFTh6FYRw2xqU9QG6+VSFh",
  render_errors: [view: DolphinWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Dolphin.PubSub, adapter: Phoenix.PubSub.PG2]

config :dolphin, :basic_auth,
  username: System.get_env("BASIC_AUTH_USERNAME"),
  password: System.get_env("BASIC_AUTH_PASSWORD")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
