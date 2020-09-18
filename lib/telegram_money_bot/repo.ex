defmodule TelegramMoneyBot.Repo do
  use Ecto.Repo,
    otp_app: :telegram_money_bot,
    adapter: Ecto.Adapters.Postgres
end
