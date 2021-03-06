# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :gupshup_demo,
  ecto_repos: [GupshupDemo.Repo]

# Configures the endpoint
config :gupshup_demo, GupshupDemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vo7ypA1ZYn71PySbftdNaTGIfOgY9jypgutxuHtJCf/GO6eb45ke7TFBWaEU6UAz",
  render_errors: [view: GupshupDemoWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: GupshupDemo.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# https://github.com/edgurgel/httpoison/issues/359
config :hackney, use_default_pool: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
