use Mix.Config

# Configure your database
config :markevich_money, MarkevichMoney.Repo,
  username: "postgres",
  password: "",
  database: "markevich_money_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
