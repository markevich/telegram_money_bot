defmodule MarkevichMoney.Pipelines do
  alias MarkevichMoney.{CallbackData, MessageData}
  alias MarkevichMoney.Pipelines.ChooseCategory, as: ChooseCategoryPipeline
  alias MarkevichMoney.Pipelines.Compliment, as: ComplimentPipeline
  alias MarkevichMoney.Pipelines.Help, as: HelpPipeline
  alias MarkevichMoney.Pipelines.ReceiveTransaction, as: ReceiveTransactionPipeline
  alias MarkevichMoney.Pipelines.SetCategory, as: SetCategoryPipeline
  alias MarkevichMoney.Pipelines.Start, as: StartPipeline

  def call(%CallbackData{callback_data: %{"pipeline" => pipeline}} = callback_data) do
    case pipeline do
      "compliment" ->
        callback_data
        |> ComplimentPipeline.call()
      "choose_category" ->
        callback_data
        |> ChooseCategoryPipeline.call()
      "set_category" ->
        callback_data
        |> SetCategoryPipeline.call()
      _ ->

        nil
    end
  end

  def call(%MessageData{message: "✉️ <click@alfa-bank.by>" <> _rest = message}) do
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
