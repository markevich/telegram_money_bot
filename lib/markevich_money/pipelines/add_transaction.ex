defmodule MarkevichMoney.Pipelines.AddTransaction do
  use MarkevichMoney.LoggerWithSentry

  alias MarkevichMoney.Steps.Transaction.{
    CreateTransaction,
    FireTransactionCreatedEvent,
    ParseCustomTransactionMessage,
    PredictCategory,
    RenderTransaction
  }

  alias MarkevichMoney.Steps.Telegram.SendMessage

  def call(%{message: input_message} = payload) do
    if ParseCustomTransactionMessage.valid_message?(input_message) do
      payload
      |> Map.from_struct()
      |> Map.put(:parsed_attributes, %{})
      |> ParseCustomTransactionMessage.call()
      |> PredictCategory.call()
      |> CreateTransaction.call()
      |> RenderTransaction.call()
      |> SendMessage.call()
      |> FireTransactionCreatedEvent.call()
    else
      # Temporary
      log_error_message("User tried to add custom transaction using unknown format")

      payload
      |> Map.from_struct()
      |> Map.put(:output_message, error_message())
      |> SendMessage.call()
    end
  end

  defp error_message do
    """
    Я не смог распознать твою команду добавления.

    Примеры команд, которые точно сработают:

    `/add 35.5 Фрукты на рынке`
    `/add Фрукты на рынке 35.5`
    """
  end
end
