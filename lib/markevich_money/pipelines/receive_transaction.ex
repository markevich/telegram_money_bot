defmodule MarkevichMoney.Pipelines.ReceiveTransaction do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  alias MarkevichMoney.Steps.Transaction.{
    CalculateAmountSign,
    FindOrCreateTransaction,
    ParseAccount,
    ParseAmount,
    ParseBalance,
    ParseCurrencyCode,
    ParseIssuedAt,
    ParseTo,
    PredictCategory,
    RenderTransaction,
    UpdateTransaction
  }

  def call(payload) do
    payload
    |> Map.put(:parsed_attributes, %{})
    |> ParseAccount.call()
    |> ParseAmount.call()
    |> CalculateAmountSign.call()
    |> ParseCurrencyCode.call()
    |> ParseBalance.call()
    |> ParseTo.call()
    |> ParseIssuedAt.call()
    |> PredictCategory.call()
    |> FindOrCreateTransaction.call()
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
