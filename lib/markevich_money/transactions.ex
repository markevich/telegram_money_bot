defmodule MarkevichMoney.Transactions do
  alias MarkevichMoney.Repo

  alias MarkevichMoney.Transactions.Transaction
  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Transactions.TransactionCategoryPrediction

  import Ecto.Query, only: [from: 2]

  def get_transaction!(id) do
    Repo.get!(Transaction, id)
    |> Repo.preload([:transaction_category, :user])
  end

  def upsert_transaction(user_id, account, type, amount, datetime) do
    lookup_hash =
      :crypto.hash(:sha, "#{account}-#{type}-#{amount}-#{datetime}") |> Base.encode16()

    Repo.insert(
      %Transaction{user_id: user_id, lookup_hash: lookup_hash},
      returning: true,
      on_conflict: [set: [lookup_hash: lookup_hash]],
      conflict_target: :lookup_hash
    )
  end

  def get_categories(), do: Repo.all(TransactionCategory)

  def update_transaction(%Transaction{} = transaction, attrs) do
    {:ok, _} =
      transaction
      |> Transaction.update_changeset(attrs)
      |> Repo.update()
  end

  def predict_category_id(target) do
    with query <- predict_category_query(target),
         %TransactionCategoryPrediction{} = prediction <- Repo.one(query) do
      prediction.transaction_category_id
    else
      _ -> nil
    end
  end

  def create_prediction(target, transaction_category_id) do
    %TransactionCategoryPrediction{
      prediction: target,
      transaction_category_id: transaction_category_id
    }
    |> Repo.insert!()
  end

  defp predict_category_query(target) do
    from p in TransactionCategoryPrediction,
      where: p.prediction == ^target,
      order_by: [desc: p.id],
      limit: 1
  end
end
