defmodule MarkevichMoney.Transactions.TransactionCategory do
  use Ecto.Schema
  alias MarkevichMoney.Gamification.TransactionCategoryLimit
  alias MarkevichMoney.Transactions.TransactionCategoryFolder

  schema "transaction_categories" do
    field :name, :string
    has_one(:transaction_category_limit, TransactionCategoryLimit)
    belongs_to(:transaction_category_folder, TransactionCategoryFolder)

    timestamps()
  end
end
