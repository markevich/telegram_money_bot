defmodule MarkevichMoney.Repo.Migrations.CreateTransactionCategory do
  use Ecto.Migration

  def change do
    create table(:transaction_categories) do
      add :name, :string

      timestamps()
    end

  end
end
