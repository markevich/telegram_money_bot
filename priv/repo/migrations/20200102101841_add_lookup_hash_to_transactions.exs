defmodule MarkevichMoney.Repo.Migrations.AddLookupHashToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :lookup_hash, :string, null: false
    end

    create index("transactions", [:lookup_hash], unique: true)
  end
end
