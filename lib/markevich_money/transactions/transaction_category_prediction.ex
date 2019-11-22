defmodule MarkevichMoney.Transactions.TransactionCategoryPrediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transaction_category_prediction" do
    field :prediction, :string
    field :transaction_category_id, :id

    timestamps()
  end

  @doc false
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:prediction, :transaction_category_id])
    |> validate_required([:prediction, :transaction_category_id])
  end
end
