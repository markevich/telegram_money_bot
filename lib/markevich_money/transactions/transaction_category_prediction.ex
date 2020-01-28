defmodule MarkevichMoney.Transactions.TransactionCategoryPrediction do
  use Ecto.Schema

  schema "transaction_category_prediction" do
    field :prediction, :string
    field :transaction_category_id, :id

    timestamps()
  end
end
