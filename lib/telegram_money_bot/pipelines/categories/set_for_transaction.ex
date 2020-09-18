defmodule TelegramMoneyBot.Pipelines.Categories.SetForTransaction do
  alias TelegramMoneyBot.Steps.Telegram.{AnswerCallback, UpdateMessage}

  alias TelegramMoneyBot.Steps.Transaction.{
    FetchTransaction,
    FireTransactionUpdatedEvent,
    RenderTransaction
  }

  alias TelegramMoneyBot.Transactions

  def call(callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> set_category()
    |> FetchTransaction.call()
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
end
