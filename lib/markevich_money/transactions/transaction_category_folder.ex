defmodule MarkevichMoney.Transactions.TransactionCategoryFolder do
  use Ecto.Schema
  alias MarkevichMoney.Transactions.TransactionCategory

  schema "transaction_category_folders" do
    field :name, :string
    field :has_single_category, :boolean
    has_many(:transaction_categories, TransactionCategory)

    timestamps()
  end
end
