# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :markevich_money,
  ecto_repos: [MarkevichMoney.Repo]

# Configures the endpoint
config :markevich_money, MarkevichMoneyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "PlSrrESn3RAQLURO2d19ck+D+EnJcZ51nDad++Tg3Ulq8VaDcQep17Tb1bOSV18B",
  render_errors: [view: MarkevichMoneyWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MarkevichMoney.PubSub,
  live_view: [signing_salt: "aevz9FQT"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# sentry
config :logger,
  backends: [:console]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :markevich_money, Oban,
  repo: MarkevichMoney.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"* * * * *", EmailProcessor},
       #  {"* * * * *", MarkevichMoney.Priorbank.SchedulerWorker},
       {"0 11 1 * *", MarkevichMoney.Gamification.Events.NewMonthStarted}
     ]},
    Oban.Plugins.Gossip,
    Bebran.Web.Plugins.Stats
  ],
  queues: [
    # TODO: Wait for https://elixirforum.com/t/oban-having-many-dynamic-queues-okay-or-a-bad-idea/36312/17
    # implementation
    # FYI: https://core.telegram.org/bots/faq#how-can-i-message-all-of-my-bot-39s-subscribers-at-once
    transactions: 1,
    events: 5,
    trackers: 5,
    reports: 2,
    mail_fetcher: 1
    # priorbank_scheduler: 1,
    # priorbank_fetcher: 5
  ]

config :markevich_money, priorbank_api_url: "https://www.prior.by"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "tg_file_ids.exs"
