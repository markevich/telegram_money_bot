defmodule MarkevichMoney.Transactions do
  alias MarkevichMoney.Repo

  alias MarkevichMoney.Transactions.Transaction
  alias MarkevichMoney.Transactions.TransactionCategory

  import Ecto.Query, only: [from: 2, order_by: 2]

  def get_transaction!(id) do
    Transaction
    |> Repo.get!(id)
    |> Repo.preload([:transaction_category, :user])
  end

  def get_user_transaction!(transaction_id, user_id) do
    from(transaction in Transaction,
      where: transaction.id == ^transaction_id,
      where: transaction.user_id == ^user_id
    )
    |> Repo.one!()
    |> Repo.preload([:transaction_category, :user])
  end

  def get_transaction_by_lookup_hash(lookup_hash) do
    from(transaction in Transaction,
      where: transaction.lookup_hash == ^lookup_hash
    )
    |> Repo.one()
  end

  def category_id_by_name_similarity(category_name) do
    from(category in TransactionCategory,
      where: fragment("similarity(?, ?) > 0.1", category.name, ^category_name),
      select: %{
        id: category.id,
        name: category.name,
        similarity: fragment("similarity(?, ?)", category.name, ^category_name)
      },
      order_by: [desc: 3],
      limit: 1
    )
    |> Repo.one()
  end

  def delete_transaction(id) do
    from(t in Transaction, where: t.id == ^id) |> Repo.delete_all()
  end

  @spec upsert_transaction(integer, String.t(), Decimal.t(), String.t()) ::
          {:exists, %Transaction{}} | {:new, %Transaction{}}
  def upsert_transaction(user_id, account, amount, issued_at) do
    lookup_hash = calculate_lookup_hash(user_id, account, amount, issued_at)

    existing_transaction = get_transaction_by_lookup_hash(lookup_hash)

    # TODO: Race condition is possible here. Use something more efficient
    if existing_transaction do
      {:exists, existing_transaction}
    else
      {:ok, transaction} =
        Repo.insert(
          %Transaction{user_id: user_id, lookup_hash: lookup_hash},
          returning: true,
          on_conflict: [set: [lookup_hash: lookup_hash]],
          conflict_target: :lookup_hash
        )

      {:new, transaction}
    end
  end

  def calculate_lookup_hash(user_id, account, amount, issued_at) do
    :crypto.hash(:sha, "#{user_id}-#{account}-#{amount}-#{issued_at}") |> Base.encode16()
  end

  def get_categories do
    TransactionCategory
    |> order_by(asc: :id)
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get(TransactionCategory, id)

  def update_transaction(%Transaction{} = transaction, attrs) do
    updated =
      transaction
      |> Transaction.update_changeset(attrs)
      |> Repo.update!()
      |> Repo.preload([:transaction_category, :user], force: true)

    {:ok, updated}
  end

  def stats(current_user, from, to) do
    query =
      from(transaction in Transaction,
        join: user in assoc(transaction, :user),
        left_join: category in assoc(transaction, :transaction_category),
        where: user.id == ^current_user.id,
        where: transaction.amount < ^0,
        where: transaction.issued_at >= ^from,
        where: transaction.issued_at <= ^to,
        group_by: [category.name, category.id],
        select: {sum(transaction.amount), coalesce(category.name, "❓Без категории"), category.id},
        order_by: [asc: 1]
      )

    Repo.all(query)
  end

  def stats(current_user, from, to, category_id) do
    query =
      from(transaction in Transaction,
        join: user in assoc(transaction, :user),
        where: user.id == ^current_user.id,
        where: transaction.amount < ^0,
        where: transaction.issued_at >= ^from,
        where: transaction.issued_at <= ^to,
        select:
          {transaction.to, transaction.custom_description, transaction.amount,
           transaction.issued_at},
        order_by: [asc: transaction.issued_at]
      )

    query_with_category =
      if category_id do
        from(
          q in query,
          where: q.transaction_category_id == ^category_id
        )
      else
        from(
          q in query,
          where: is_nil(q.transaction_category_id)
        )
      end

    Repo.all(query_with_category)
  end

  def get_category_monthly_spendings(user_id, category_id, exclude_transaction_ids \\ []) do
    beginning_of_month = Timex.beginning_of_month(Timex.now())
    end_of_month = Timex.end_of_month(Timex.now())

    query =
      from(transaction in Transaction,
        join: user in assoc(transaction, :user),
        join: category in assoc(transaction, :transaction_category),
        where: user.id == ^user_id,
        where: category.id == ^category_id,
        where: transaction.amount < ^0,
        where: transaction.issued_at >= ^beginning_of_month,
        where: transaction.issued_at <= ^end_of_month,
        where: transaction.id not in ^exclude_transaction_ids,
        select: sum(transaction.amount)
      )

    case Repo.one(query) do
      nil -> 0
      decimal -> abs(Decimal.to_float(decimal))
    end
  end

  def predict_category_id(transaction_to, user_id) do
    query_for_current_user =
      from t in Transaction,
        select: t.transaction_category_id,
        where: t.user_id == ^user_id,
        where: t.to == ^transaction_to,
        where: not is_nil(t.transaction_category_id),
        order_by: [desc: t.id],
        limit: 1

    query_for_all_users =
      from t in Transaction,
        select: t.transaction_category_id,
        where: t.to == ^transaction_to,
        where: not is_nil(t.transaction_category_id),
        order_by: [desc: t.id],
        limit: 1

    similarity_for_current_user =
      from t in Transaction,
        select: t.transaction_category_id,
        where: t.user_id == ^user_id,
        where: fragment("similarity(?, ?) > 0.7", t.to, ^transaction_to),
        where: not is_nil(t.transaction_category_id),
        order_by: [desc: fragment("similarity(?, ?)", t.to, ^transaction_to)],
        limit: 1

    similarity_for_all_users =
      from t in Transaction,
        select: t.transaction_category_id,
        where: fragment("similarity(?, ?) > 0.7", t.to, ^transaction_to),
        where: not is_nil(t.transaction_category_id),
        order_by: [desc: fragment("similarity(?, ?)", t.to, ^transaction_to)],
        limit: 1

    Repo.one(query_for_current_user) ||
      Repo.one(query_for_all_users) ||
      Repo.one(similarity_for_current_user) ||
      Repo.one(similarity_for_all_users)
  end
end
