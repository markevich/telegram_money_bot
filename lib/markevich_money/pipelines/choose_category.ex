defmodule MarkevichMoney.Pipelines.ChooseCategory do
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage}

  alias MarkevichMoney.Transactions

  def call(callback_data) do
    callback_data
    |> Map.from_struct()
    |> insert_categories()
    |> Map.put(:output_message, callback_data.message_text)
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  defp insert_categories(%{callback_data: %{"id" => transaction_id}} = payload) do
    keyboard =
      Transactions.get_categories()
      |> Enum.map(fn category ->
        %Nadia.Model.InlineKeyboardButton{
          text: category.name,
          callback_data:
            Jason.encode!(%{pipeline: "set_category", id: transaction_id, c_id: category.id})
        }
      end)
      |> Enum.chunk_every(2)

    reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard}

    payload
    |> Map.put(:reply_markup, reply_markup)
  end
end
