defmodule MarkevichMoney.Pipelines.Categories.SetForTransaction do
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage}

  alias MarkevichMoney.Steps.Transaction.{
    FetchTransaction,
    FireTransactionUpdatedEvent,
    RenderTransaction
  }

  alias MarkevichMoney.Transactions

  def call(callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> set_category()
    |> FetchTransaction.call()
    |> save_prediction()
    |> RenderTransaction.call()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
    |> FireTransactionUpdatedEvent.call()
  end

  defp fetch_transaction_id(%{callback_data: %{"id" => transaction_id}} = payload) do
    payload
    |> Map.put(:transaction_id, transaction_id)
  end

  defp set_category(
         %{callback_data: %{"c_id" => category_id}, transaction: transaction} = payload
       ) do
    Transactions.update_transaction(transaction, %{transaction_category_id: category_id})

    payload
  end

  defp save_prediction(%{transaction: transaction} = payload) do
    Transactions.create_prediction(transaction.to, transaction.transaction_category_id)

    payload
  end
end
