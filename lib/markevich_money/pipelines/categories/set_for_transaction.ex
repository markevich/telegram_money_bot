defmodule MarkevichMoney.Pipelines.Categories.SetForTransaction do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage}

  alias MarkevichMoney.Steps.Transaction.{
    FetchTransaction,
    FireTransactionUpdatedEvent,
    RenderTransaction
  }

  alias MarkevichMoney.Transactions

  def call(callback_data) do
    payload = Map.from_struct(callback_data)

    case payload do
      %{callback_data: %{"f_id" => _folder_id}} -> proceed_folder_selection(payload)
      %{callback_data: %{"c_id" => _category_id}} -> proceed_category_selection(payload)
    end
  end

  def proceed_folder_selection(payload) do
    folder = Transactions.get_category_folder!(payload.callback_data["f_id"])

    if folder.has_single_category do
      the_only_one_category = List.first(folder.transaction_categories)
      payload = put_in(payload, [:callback_data, "c_id"], the_only_one_category.id)
      proceed_category_selection(payload)
    else
      payload
      |> fetch_transaction_id()
      |> FetchTransaction.call()
      |> RenderTransaction.call()
      |> insert_categories_keyboard(folder)
      |> UpdateMessage.call()
      |> AnswerCallback.call()
    end
  end

  # Set category
  def proceed_category_selection(payload) do
    payload
    |> fetch_transaction_id()
    |> FetchTransaction.call()
    |> set_category()
    |> FetchTransaction.call()
    |> RenderTransaction.call()
    |> UpdateMessage.call()
    |> AnswerCallback.call()
    |> FireTransactionUpdatedEvent.call()
  end

  defp insert_categories_keyboard(payload, folder) do
    keyboard =
      folder.transaction_categories
      |> Enum.map(fn category ->
        %Nadia.Model.InlineKeyboardButton{
          text: category.name,
          callback_data:
            Jason.encode!(%{
              pipeline: @set_category_callback,
              id: payload.transaction_id,
              c_id: category.id
            })
        }
      end)
      |> Enum.chunk_every(2)
      |> Enum.concat([
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "⬅️ Назад к категориям",
            callback_data:
              Jason.encode!(%{
                pipeline: @choose_category_callback,
                id: payload.transaction_id,
                mode: @choose_category_full_mode
              })
          }
        ]
      ])

    reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard}

    payload
    |> Map.put(:reply_markup, reply_markup)
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
