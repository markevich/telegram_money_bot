defmodule MarkevichMoney.Repo.Migrations.AddCustomDescriptionToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :custom_description, :string, null: true
    end
  end
end
