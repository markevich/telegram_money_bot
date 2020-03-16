defmodule MarkevichMoney.Repo.Migrations.AddNotNullAndUniqueToColumns do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :telegram_chat_id, :integer, null: false
      modify :name, :string, null: false
    end
    create unique_index(:users, [:telegram_chat_id])
    create unique_index(:users, [:name])

    alter table(:transactions) do
      modify :user_id, :bigint, null: false
    end

    alter table(:transaction_categories) do
      modify :name, :string, null: false
    end
    create unique_index(:transaction_categories, [:name])
  end
end
