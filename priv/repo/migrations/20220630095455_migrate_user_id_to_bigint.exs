defmodule MarkevichMoney.Repo.Migrations.MigrateUserIdToBigint do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:telegram_chat_id, :bigint)
    end
  end
end
