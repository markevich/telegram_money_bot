defmodule MarkevichMoney.Repo.Migrations.CreateTransactionCategoryLimitsTable do
  use Ecto.Migration

  def change do
    create table(:transaction_category_limits) do
      add(:transaction_category_id, references(:transaction_categories, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:limit, :integer, default: 0, null: false)


      timestamps()
    end

    create unique_index(:transaction_category_limits, [:transaction_category_id, :user_id])
  end
end
