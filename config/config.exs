# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :markevich_money,
  ecto_repos: [MarkevichMoney.Repo]

# Configures the endpoint
config :markevich_money, MarkevichMoneyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "PlSrrESn3RAQLURO2d19ck+D+EnJcZ51nDad++Tg3Ulq8VaDcQep17Tb1bOSV18B",
  render_errors: [view: MarkevichMoneyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MarkevichMoney.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# sentry
config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :logger, Sentry.LoggerBackend, ignore_plug: true
#

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
