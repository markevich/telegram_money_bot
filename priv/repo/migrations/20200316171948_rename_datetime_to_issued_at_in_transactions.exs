defmodule TelegramMoneyBot.Repo.Migrations.RenameDatetimeToIssuedAtInTransactions do
  use Ecto.Migration

  def change do
    rename table(:transactions), :datetime, to: :issued_at
  end
end
