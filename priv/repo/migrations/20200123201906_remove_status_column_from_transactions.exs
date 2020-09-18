defmodule TelegramMoneyBot.Repo.Migrations.RemoveStatusColumnFromTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      remove(:status, :string)
    end
  end
end
