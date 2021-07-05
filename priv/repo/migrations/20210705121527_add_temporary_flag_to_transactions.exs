defmodule MarkevichMoney.Repo.Migrations.AddTemporaryFlagToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :temporary, :boolean, null: false, default: false
    end
  end
end
