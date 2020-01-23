defmodule MarkevichMoney.Pipelines.AddTransaction do
  alias MarkevichMoney.Steps.Transaction.{
    ParseCustomTransactionMessage,
    PredictCategory,
    CreateTransaction,
    RenderTransaction
  }

  alias MarkevichMoney.Steps.Telegram.SendMessage

  def call(payload) do
    payload
    |> Map.put(:parsed_attributes, %{})
    |> ParseCustomTransactionMessage.call()
    |> PredictCategory.call()
    |> CreateTransaction.call()
    |> RenderTransaction.call()
    |> SendMessage.call()
  end
end
