import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :markevich_money, MarkevichMoneyWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :markevich_money, Oban, testing: :manual

import_config "test.secret.exs"
