defmodule MarkevichMoney.Repo do
  use Ecto.Repo,
    otp_app: :markevich_money,
    adapter: Ecto.Adapters.Postgres
end
