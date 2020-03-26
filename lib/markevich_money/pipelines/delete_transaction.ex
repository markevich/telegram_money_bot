defmodule MarkevichMoney.Pipelines.DeleteTransaction do
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Steps.Transaction.{DeleteTransaction, FetchTransaction, RenderTransaction}
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage}

  def call(%CallbackData{callback_data: %{"action" => "ask"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> RenderTransaction.call()
    |> put_confirmation_buttons()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  def call(%CallbackData{callback_data: %{"action" => "dlt"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> DeleteTransaction.call()
    |> Map.put(:output_message, "Удалено")
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  def call(%CallbackData{callback_data: %{"action" => "cnl"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> RenderTransaction.call()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  defp put_confirmation_buttons(%{callback_data: %{"id" => transaction_id}} = payload) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "❌ Удалить ❌",
            callback_data:
              Jason.encode!(%{pipeline: "dlt_trn", action: "dlt", id: transaction_id})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "Отмена",
            callback_data:
              Jason.encode!(%{pipeline: "dlt_trn", action: "cnl", id: transaction_id})
          }
        ]
      ]
    }

    payload
    |> Map.put(:reply_markup, reply_markup)
  end

  defp fetch_transaction_id(%{callback_data: %{"id" => transaction_id}} = payload) do
    payload
    |> Map.put(:transaction_id, transaction_id)
  end
end
