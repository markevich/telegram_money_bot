defmodule MarkevichMoney.Pipelines.IgnoreTransaction do
  alias MarkevichMoney.Steps.Transaction.DeleteTransaction
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage}

  def call(callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> DeleteTransaction.call()
    |> Map.put(:output_message, "Удалено")
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  defp fetch_transaction_id(%{callback_data: %{"id" => transaction_id}} = payload) do
    payload
    |> Map.put(:transaction_id, transaction_id)
  end
end
