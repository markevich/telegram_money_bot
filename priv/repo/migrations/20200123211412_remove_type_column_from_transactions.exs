defmodule TelegramMoneyBot.Repo.Migrations.RemoveTypeColumnFromTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      remove(:type, :string)
    end
  end
end
