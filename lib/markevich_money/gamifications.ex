defmodule MarkevichMoney.Gamifications do
  import Ecto.Query, only: [from: 2]

  alias MarkevichMoney.Repo
  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Users.User

  def list_categories_limits(%User{id: user_id}) do
    query =
      from(category in TransactionCategory,
        left_join: category_limit in assoc(category, :transaction_category_limit),
        left_join: user in assoc(category_limit, :user),
        where: user.id == ^user_id or is_nil(user.id),
        order_by: [asc: category.id],
        preload: [transaction_category_limit: category_limit]
      )

    Repo.all(query)
  end
end
