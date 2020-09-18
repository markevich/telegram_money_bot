defmodule TelegramMoneyBot.Repo.Migrations.CreateTransactionCategoryPrediction do
  use Ecto.Migration

  def change do
    create table(:transaction_category_prediction) do
      add :prediction, :string, null: false
      add :transaction_category_id, references(:transaction_categories, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:transaction_category_prediction, [:transaction_category_id])
  end
end
