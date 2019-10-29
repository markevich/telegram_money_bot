defmodule MarkevichMoney.Transactions.TransactionCategory do
  use Ecto.Schema

  schema "transaction_categories" do
    field :name, :string

    timestamps()
  end
end
