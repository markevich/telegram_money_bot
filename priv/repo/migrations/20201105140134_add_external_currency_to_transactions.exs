defmodule MarkevichMoney.Repo.Migrations.AddExternalCurrencyToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:external_currency, :string)
      add(:external_amount, :decimal)
    end
  end
end
