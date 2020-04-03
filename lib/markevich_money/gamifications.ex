defmodule MarkevichMoney.Gamifications do
  import Ecto.Query, only: [from: 2]

  alias MarkevichMoney.Gamification.TransactionCategoryLimit
  alias MarkevichMoney.Repo
  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Users.User

  def get_category_limit_value(user_id, category_id) do
    query =
      from(limit in TransactionCategoryLimit,
        where: limit.user_id == ^user_id and limit.transaction_category_id == ^category_id
      )

    case Repo.one(query) do
      nil -> 0
      record -> record.limit
    end
  end

  def list_categories_limits(%User{id: user_id}) do
    query =
      from(category in TransactionCategory,
        left_join: category_limit in assoc(category, :transaction_category_limit),
        on: category_limit.user_id == ^user_id,
        order_by: [asc: category.id],
        preload: [transaction_category_limit: category_limit]
      )

    Repo.all(query)
  end

  def set_transaction_category_limit!(transaction_category_id, user_id, limit) do
    transaction_category_limit =
      upsert_transaction_category_limit!(transaction_category_id, user_id)

    TransactionCategoryLimit.changeset(transaction_category_limit, %{limit: limit})
    |> Repo.update!()
  end

  def upsert_transaction_category_limit!(transaction_category_id, user_id) do
    attrs = %{transaction_category_id: transaction_category_id, user_id: user_id}

    %TransactionCategoryLimit{}
    |> TransactionCategoryLimit.changeset(attrs)
    |> Repo.insert!(
      returning: true,
      on_conflict: {:replace, [:transaction_category_id, :user_id]},
      conflict_target: [:transaction_category_id, :user_id]
    )
  end
end
