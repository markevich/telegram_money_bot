defmodule MarkevichMoney.Pipelines do
  alias MarkevichMoney.{CallbackData, MessageData}
  alias MarkevichMoney.Pipelines.ChooseCategory, as: ChooseCategoryPipeline
  alias MarkevichMoney.Pipelines.Compliment, as: ComplimentPipeline
  alias MarkevichMoney.Pipelines.Help, as: HelpPipeline
  alias MarkevichMoney.Pipelines.ReceiveTransaction, as: ReceiveTransactionPipeline
  alias MarkevichMoney.Pipelines.SetCategory, as: SetCategoryPipeline
  alias MarkevichMoney.Pipelines.Start, as: StartPipeline
  alias MarkevichMoney.Pipelines.Stats, as: StatsPipeline
  alias MarkevichMoney.Pipelines.AddTransaction, as: AddTransactionPipeline
  alias MarkevichMoney.Users
  alias MarkevichMoney.Steps.Telegram.SendMessage

  def call(%CallbackData{chat_id: chat_id, current_user: nil} = callback_data)
      when is_integer(chat_id) do
    user = Users.get_user_by_chat_id(chat_id)

    call(%CallbackData{callback_data | current_user: user})
  end

  def call(%CallbackData{callback_data: %{"pipeline" => pipeline}} = callback_data) do
    case pipeline do
      "compliment" ->
        callback_data
        |> ComplimentPipeline.call()

      "choose_category" ->
        callback_data
        |> ChooseCategoryPipeline.call()

      "stats" ->
        callback_data
        |> StatsPipeline.call()

      "set_category" ->
        callback_data
        |> SetCategoryPipeline.call()

      _ ->
        nil
    end
  end

  def call(%MessageData{current_user: nil, username: username} = message_data)
      when is_binary(username) do
    user = Users.get_user_by_username(username)

    if user do
      call(%MessageData{message_data | current_user: user})
    end
  end

  def call(%MessageData{current_user: nil, chat_id: chat_id} = message_data)
      when is_integer(chat_id) do
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

  def call(%MessageData{message: "Карта" <> _rest = message, current_user: user}) do
    %{
      input_message: message,
      current_user: user
    }
    |> ReceiveTransactionPipeline.call()
  end

  def call(%MessageData{message: "/help", current_user: user}) do
    HelpPipeline.call(%MessageData{current_user: user})
  end

  def call(%MessageData{message: "/start", current_user: user}) do
    StartPipeline.call(%MessageData{current_user: user})
  end

  def call(%MessageData{message: "/stats", current_user: user}) do
    StatsPipeline.call(%MessageData{current_user: user})
  end

  def call(%MessageData{message: "/add" <> _rest = message, current_user: user}) do
    AddTransactionPipeline.call(%MessageData{message: message, current_user: user})
  end

  def call(%MessageData{message: _message}) do
  end
end
