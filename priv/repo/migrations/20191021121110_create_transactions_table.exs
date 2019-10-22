defmodule MarkevichMoney.Repo.Migrations.CreateTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add(:account, :string)
      add(:datetime, :naive_datetime)
      add(:amount, :decimal)
      add(:currency_code, :string)
      add(:balance, :decimal)
      add(:target, :string)
      add(:type, :string)

      add(:status, :string)

      timestamps()
    end
  end
end
