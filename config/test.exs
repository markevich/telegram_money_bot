use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :telegram_money_bot, TelegramMoneyBotWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :info

config :telegram_money_bot, Oban, crontab: false, queues: false, plugins: false

import_config "test.secret.exs"
