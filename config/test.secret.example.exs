use Mix.Config

# Configure your database
config :markevich_money, MarkevichMoney.Repo,
  username: "postgres",
  password: "",
  database: "markevich_money_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :nadia, token: "bot token"
config :markevich_money, mailgun_api_key: "api key"
