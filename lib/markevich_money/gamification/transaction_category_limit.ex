defmodule MarkevichMoney.Gamification.TransactionCategoryLimit do
  use Ecto.Schema
  import Ecto.Changeset

  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Users.User

  schema "transaction_category_limits" do
    field :limit, :integer, default: 0
    belongs_to(:transaction_category, TransactionCategory)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(category_limit, attrs) do
    category_limit
    |> cast(attrs, [
      :user_id,
      :transaction_category_id,
      :limit
    ])
    |> foreign_key_constraint(:transaction_category_id)
    |> foreign_key_constraint(:user_id)
    |> validate_required([:user_id, :transaction_category_id, :limit])
  end
end
