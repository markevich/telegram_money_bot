use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :markevich_money, MarkevichMoney.Repo,
  username: "postgres",
  password: "",
  database: "markevich_money_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :nadia, token: "bot token"
config :markevich_money, mailgun_api_key: "api key"
