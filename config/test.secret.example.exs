import Config

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

if System.get_env("GITHUB_ACTIONS") do
  config :markevich_money, MarkevichMoney.Repo,
    url: System.get_env("DATABASE_URL"),
    show_sensitive_data_on_connection_error: true
end

config :nadia, token: "bot token"
config :markevich_money, priorbank_api_url: "https://www.fobar.foo"
