defmodule MarkevichMoney.Repo.Migrations.CreateTransactionCategoryFolders do
  use Ecto.Migration

  def change do
    create table(:transaction_category_folders) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:transaction_category_folders, [:name])

    alter table(:transaction_categories) do
      add :transaction_category_folder_id, references(:transaction_category_folders)
    end

    create index(:transaction_categories, [:transaction_category_folder_id])
  end
end
