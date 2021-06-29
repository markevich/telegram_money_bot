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
    |> insert_folders()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  defp fetch_transaction_id(%{callback_data: %{"id" => transaction_id}} = payload) do
    payload
    |> Map.put(:transaction_id, transaction_id)
  end

  defp insert_folders(%{transaction: %{id: transaction_id, user_id: user_id}} = payload) do
    keyboard =
      Transactions.get_folders_ordered_by_popularity(user_id)
      |> Enum.map(fn folder ->
        %Nadia.Model.InlineKeyboardButton{
          text: folder_name(folder),
          callback_data:
            Jason.encode!(%{
              pipeline: @set_category_or_folder_callback,
              id: transaction_id,
              f_id: folder.id
            })
        }
      end)
      |> Enum.chunk_every(2)
      |> apply_categories_keyboard_mode(payload[:callback_data]["mode"], transaction_id)

    reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard}

    payload
    |> Map.put(:reply_markup, reply_markup)
  end

  defp folder_name(folder) do
    if folder.has_single_category do
      folder.name
    else
      "#{folder.name}/"
    end
  end

  defp apply_categories_keyboard_mode(keyboard, keyboard_mode, transaction_id) do
    case keyboard_mode do
      mode when mode in [@choose_category_folder_short_mode, nil] ->
        keyboard
        |> Enum.take(4)
        |> Enum.concat([
          [
            %Nadia.Model.InlineKeyboardButton{
              text: "☰ Показать больше категорий️",
              callback_data:
                Jason.encode!(%{
                  pipeline: @choose_category_folder_callback,
                  id: transaction_id,
                  mode: @choose_category_folder_full_mode
                })
            }
          ]
        ])

      @choose_category_folder_full_mode ->
        keyboard
    end
  end
end
