defmodule MarkevichMoney.Transactions.TransactionCategoryPrediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transaction_category_prediction" do
    field :prediction, :string
    field :transaction_category_id, :id

    timestamps()
  end

  @doc false
  def changeset(category_prediction, attrs) do
    category_prediction
    |> cast(attrs, [:prediction])
    |> validate_required([:prediction])
  end
end
