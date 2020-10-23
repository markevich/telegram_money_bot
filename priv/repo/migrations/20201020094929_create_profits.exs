defmodule MarkevichMoney.Repo.Migrations.CreateProfits do
  use Ecto.Migration

  def change do
    create table(:profits) do
      add :amount, :decimal, null: false
      add :description, :string
      add :date, :date, null: false

      timestamps()
    end
  end
end
