defmodule MarkevichMoney.Gamification.TransactionCategoryLimit do
  use Ecto.Schema
  # import Ecto.Changeset

  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Users.User

  schema "transaction_category_limits" do
    field :limit, :integer, default: 0
    belongs_to(:transaction_category, TransactionCategory)
    belongs_to(:user, User)

    timestamps()
  end
end
