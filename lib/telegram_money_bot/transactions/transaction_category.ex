defmodule TelegramMoneyBot.Transactions.TransactionCategory do
  use Ecto.Schema
  alias TelegramMoneyBot.Gamification.TransactionCategoryLimit

  schema "transaction_categories" do
    field :name, :string
    has_one(:transaction_category_limit, TransactionCategoryLimit)

    timestamps()
  end
end
