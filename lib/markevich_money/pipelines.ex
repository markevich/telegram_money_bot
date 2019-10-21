defmodule MarkevichMoney.Pipelines do
  alias MarkevichMoney.{CallbackData, MessageData}
  alias MarkevichMoney.Pipelines.Compliment, as: ComplimentPipeline
  alias MarkevichMoney.Pipelines.Help, as: HelpPipeline
  alias MarkevichMoney.Pipelines.ReceiveTransaction, as: ReceiveTransactionPipeline
  alias MarkevichMoney.Pipelines.Start, as: StartPipeline

  def call(%CallbackData{data: callback_data, id: callback_id}) do
    case callback_data["pipeline"] do
      "compliment" ->
        %{callback_id: callback_id}
        |> ComplimentPipeline.call()

      _ ->
        nil
    end
  end

  def call(%MessageData{message: "Карта" <> _rest = message}) do
    %{input_message: message}
    |> ReceiveTransactionPipeline.call()
  end

  def call(%MessageData{message: "/help"}) do
    HelpPipeline.call(%{})
  end

  def call(%MessageData{message: "/start"}) do
    StartPipeline.call(%{})
  end

  def call(%MessageData{message: _message}) do
  end
end
