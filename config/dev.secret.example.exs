use Mix.Config

# Configure your database
config :telegram_money_bot, TelegramMoneyBot.Repo,
  username: "postgres",
  password: "",
  database: "telegram_money_bot_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :nadia, token: "bot token"
config :telegram_money_bot, mailgun_api_key: "api key"
