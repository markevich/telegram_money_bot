defmodule TelegramMoneyBot.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:telegram_chat_id, :bigint)

      timestamps()
    end

    alter table(:transactions) do
      add :user_id, references(:users, on_delete: :nothing)
    end
    create index(:transactions, [:user_id])
  end
end
