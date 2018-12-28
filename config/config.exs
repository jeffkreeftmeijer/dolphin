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

config :dolphin, :github_credentials,
  username: System.get_env("GITHUB_USERNAME"),
  repository: System.get_env("GITHUB_REPOSITORY"),
  access_token: System.get_env("GITHUB_ACCESS_TOKEN")

config :dolphin, :twitter_credentials, username: System.get_env("TWITTER_USERNAME")

config :extwitter, :oauth,
  consumer_key: System.get_env("TWITTER_CONSUMER_KEY"),
  consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET"),
  access_token: System.get_env("TWITTER_ACCESS_TOKEN"),
  access_token_secret: System.get_env("TWITTER_TOKEN_SECRET")

config :dolphin, :mastodon_credentials,
  base_url: System.get_env("MASTODON_BASE_URL"),
  bearer_token: System.get_env("MASTODON_BEARER_TOKEN")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
