use Mix.Config

# Configure your database
config :markevich_money, MarkevichMoney.Repo,
  username: "postgres",
  password: "postgres",
  database: "markevich_money_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :markevich_money, MarkevichMoneyWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
