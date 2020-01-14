defmodule MarkevichMoney.Pipelines do
  alias MarkevichMoney.{CallbackData, MessageData}
  alias MarkevichMoney.Pipelines.ChooseCategory, as: ChooseCategoryPipeline
  alias MarkevichMoney.Pipelines.Compliment, as: ComplimentPipeline
  alias MarkevichMoney.Pipelines.Help, as: HelpPipeline
  alias MarkevichMoney.Pipelines.ReceiveTransaction, as: ReceiveTransactionPipeline
  alias MarkevichMoney.Pipelines.SetCategory, as: SetCategoryPipeline
  alias MarkevichMoney.Pipelines.Start, as: StartPipeline
  alias MarkevichMoney.Users
  alias MarkevichMoney.Steps.Telegram.SendMessage

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

  def call(%MessageData{current_user: nil, chat_id: chat_id} = message_data) do
    user = Users.get_user_by_chat_id(chat_id)

    if user do
      call(%MessageData{message_data | current_user: user})
    else
      SendMessage.call(%{output_message: "Unauthorized", chat_id: chat_id})
    end
  end

  def call(%MessageData{message: "✉️ <click@alfa-bank.by>" <> _rest = message, current_user: user}) do
    %{
      input_message: message,
      current_user: user
    }
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
