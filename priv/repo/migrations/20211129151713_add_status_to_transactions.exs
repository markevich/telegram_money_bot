defmodule MarkevichMoney.Repo.Migrations.AddStatusToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :status, :string, null: true, default: "normal"
    end
  end
end
