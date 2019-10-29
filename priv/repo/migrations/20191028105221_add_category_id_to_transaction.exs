defmodule MarkevichMoney.Repo.Migrations.AddCategoryIdToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :transaction_category_id, references(:transaction_categories, on_delete: :nothing)
    end
    create index(:transactions, [:transaction_category_id])
  end
end
