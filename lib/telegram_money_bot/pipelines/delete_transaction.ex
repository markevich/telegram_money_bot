defmodule TelegramMoneyBot.Pipelines.DeleteTransaction do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.CallbackData

  alias TelegramMoneyBot.Steps.Transaction.{
    DeleteTransaction,
    FetchTransaction,
    RenderTransaction
  }

  alias TelegramMoneyBot.Steps.Telegram.{AnswerCallback, UpdateMessage}

  def call(
        %CallbackData{callback_data: %{"action" => @delete_transaction_callback_prompt}} =
          callback_data
      ) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> RenderTransaction.call()
    |> put_confirmation_buttons()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  def call(
        %CallbackData{callback_data: %{"action" => @delete_transaction_callback_confirm}} =
          callback_data
      ) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> DeleteTransaction.call()
    |> Map.put(:output_message, "Удалено")
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  def call(
        %CallbackData{callback_data: %{"action" => @delete_transaction_callback_cancel}} =
          callback_data
      ) do
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
              Jason.encode!(%{
                pipeline: @delete_transaction_callback,
                action: @delete_transaction_callback_confirm,
                id: transaction_id
              })
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "Отмена",
            callback_data:
              Jason.encode!(%{
                pipeline: @delete_transaction_callback,
                action: @delete_transaction_callback_cancel,
                id: transaction_id
              })
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
