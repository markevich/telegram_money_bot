use Mix.Config

# Configure your database
config :markevich_money, MarkevichMoney.Repo,
  username: "postgres",
  password: "",
  database: "markevich_money_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :nadia,
  token: "bot token"
