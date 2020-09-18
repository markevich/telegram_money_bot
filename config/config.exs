# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :telegram_money_bot,
  ecto_repos: [TelegramMoneyBot.Repo]

# Configures the endpoint
config :telegram_money_bot, TelegramMoneyBotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "PlSrrESn3RAQLURO2d19ck+D+EnJcZ51nDad++Tg3Ulq8VaDcQep17Tb1bOSV18B",
  render_errors: [view: TelegramMoneyBotWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: TelegramMoneyBot.PubSub,
  live_view: [signing_salt: "aevz9FQT"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# sentry
config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :logger, Sentry.LoggerBackend,
  # Send messages like `Logger.error("error")` to Sentry
  capture_log_messages: true,
  # Do not exclude exceptions from Plug/Cowboy
  excluded_domains: [],
  metadata: [:extra]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :telegram_money_bot, Oban,
  repo: TelegramMoneyBot.Repo,
  # plugins: [{Oban.Plugins.Pruner, max_age: 60}, Oban.Pro.Plugins.Lifeline, Oban.Web.Plugins.Stats],
  plugins: [{Oban.Plugins.Pruner, max_age: 60}],
  queues: [events: 5, trackers: 5]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
