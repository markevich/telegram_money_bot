defmodule TelegramMoneyBot.Pipelines.AddTransaction do
  alias TelegramMoneyBot.Steps.Transaction.{
    CreateTransaction,
    FireTransactionCreatedEvent,
    ParseCustomTransactionMessage,
    PredictCategory,
    RenderTransaction
  }

  alias TelegramMoneyBot.Steps.Telegram.SendMessage

  def call(payload) do
    payload
    |> Map.from_struct()
    |> Map.put(:parsed_attributes, %{})
    |> ParseCustomTransactionMessage.call()
    |> PredictCategory.call()
    |> CreateTransaction.call()
    |> RenderTransaction.call()
    |> SendMessage.call()
    |> FireTransactionCreatedEvent.call()
  end
end
