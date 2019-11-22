defmodule MarkevichMoney.Pipelines.ReceiveTransaction do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  alias MarkevichMoney.Steps.Transaction.{
    CreateTransaction,
    ParseAccount,
    ParseAmount,
    ParseBalance,
    ParseCurrencyCode,
    ParseDateTime,
    ParseTarget,
    ParseType,
    PredictCategory,
    RenderTransaction,
    UpdateTransaction
  }

  def call(payload) do
    payload
    |> CreateTransaction.call()
    |> Map.put(:parsed_attributes, %{})
    |> ParseAccount.call()
    |> ParseAmount.call()
    |> ParseCurrencyCode.call()
    |> ParseBalance.call()
    |> ParseTarget.call()
    |> ParseType.call()
    |> ParseDateTime.call()
    |> PredictCategory.call()
    |> UpdateTransaction.call()
    |> insert_buttons()
    |> RenderTransaction.call()
    |> SendMessage.call()
  end

  def insert_buttons(%{transaction: %{id: transaction_id}} = payload) do
    callback_data = Jason.encode!(%{pipeline: "choose_category", id: transaction_id})

    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Выбрать категорию",
            callback_data: callback_data
          }
        ]
      ]
    }

    payload
    |> Map.put(:reply_markup, reply_markup)
  end
end
