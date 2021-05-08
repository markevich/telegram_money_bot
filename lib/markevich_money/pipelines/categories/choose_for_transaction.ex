defmodule MarkevichMoney.Pipelines.Categories.ChooseForTransaction do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage}
  alias MarkevichMoney.Steps.Transaction.{FetchTransaction, RenderTransaction}

  alias MarkevichMoney.Transactions

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

  defp insert_categories(%{transaction: %{id: transaction_id, user_id: user_id}} = payload) do
    keyboard =
      Transactions.get_categories_ordered_by_popularity(user_id)
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
      |> apply_categories_keyboard_mode(payload[:callback_data]["mode"], transaction_id)

    reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard}

    payload
    |> Map.put(:reply_markup, reply_markup)
  end

  defp apply_categories_keyboard_mode(keyboard, keyboard_mode, transaction_id) do
    case keyboard_mode do
      mode when mode in [@choose_category_short_mode, nil] ->
        keyboard
        |> Enum.take(4)
        |> Enum.concat([
          [
            %Nadia.Model.InlineKeyboardButton{
              text: "☰ Показать больше категорий️",
              callback_data:
                Jason.encode!(%{
                  pipeline: @choose_category_callback,
                  id: transaction_id,
                  mode: @choose_category_full_mode
                })
            }
          ]
        ])

      @choose_category_full_mode ->
        keyboard
    end
  end
end
