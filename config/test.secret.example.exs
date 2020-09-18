use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :telegram_money_bot, TelegramMoneyBot.Repo,
  username: "postgres",
  password: "",
  database: "telegram_money_bot_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :nadia, token: "bot token"
config :telegram_money_bot, mailgun_api_key: "api key"
