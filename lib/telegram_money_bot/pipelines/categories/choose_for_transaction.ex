defmodule TelegramMoneyBot.Pipelines.Categories.ChooseForTransaction do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.Steps.Telegram.{AnswerCallback, UpdateMessage}
  alias TelegramMoneyBot.Steps.Transaction.{FetchTransaction, RenderTransaction}

  alias TelegramMoneyBot.Transactions

  def call(callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> RenderTransaction.call()
    |> insert_categories()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  defp fetch_transaction_id(%{callback_data: %{"id" => transaction_id}} = payload) do
    payload
    |> Map.put(:transaction_id, transaction_id)
  end

  defp insert_categories(%{transaction: %{id: transaction_id}} = payload) do
    keyboard =
      Transactions.get_categories()
      |> Enum.map(fn category ->
        %Nadia.Model.InlineKeyboardButton{
          text: category.name,
          callback_data:
            Jason.encode!(%{
              pipeline: @set_category_callback,
              id: transaction_id,
              c_id: category.id
            })
        }
      end)
      |> Enum.chunk_every(2)

    reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard}

    payload
    |> Map.put(:reply_markup, reply_markup)
  end
end
