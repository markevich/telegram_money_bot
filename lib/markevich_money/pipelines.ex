defmodule MarkevichMoney.Pipelines do
  alias MarkevichMoney.{CallbackData, MessageData}
  alias MarkevichMoney.Pipelines.AddTransaction, as: AddTransactionPipeline
  alias MarkevichMoney.Pipelines.ChooseCategory, as: ChooseCategoryPipeline
  alias MarkevichMoney.Pipelines.DeleteTransaction, as: DeleteTransactionPipeline
  alias MarkevichMoney.Pipelines.Help, as: HelpPipeline
  alias MarkevichMoney.Pipelines.ReceiveTransaction, as: ReceiveTransactionPipeline
  alias MarkevichMoney.Pipelines.SetCategory, as: SetCategoryPipeline
  alias MarkevichMoney.Pipelines.Stats.Callbacks, as: StatsCallbacksPipeline
  alias MarkevichMoney.Pipelines.Stats.Messages, as: StatsMessagesPipeline
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Users

  def call(%CallbackData{chat_id: chat_id, current_user: nil} = callback_data)
      when is_integer(chat_id) do
    user = Users.get_user_by_chat_id!(chat_id)

    call(%CallbackData{callback_data | current_user: user})
  end

  def call(%CallbackData{callback_data: %{"pipeline" => "choose_category"}} = callback_data) do
    callback_data
    |> ChooseCategoryPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => "stats"}} = callback_data) do
    callback_data
    |> StatsCallbacksPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => "set_category"}} = callback_data) do
    callback_data
    |> SetCategoryPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => "dlt_trn"}} = callback_data) do
    callback_data
    |> DeleteTransactionPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => _}} = callback_data) do
    callback_data
  end

  def call(%MessageData{current_user: nil, username: username} = message_data)
      when is_binary(username) do
    user = Users.get_user_by_username(username)

    if user do
      call(%MessageData{message_data | current_user: user})
    else
      message_data
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

  def call(%MessageData{message: "/stats", current_user: user}) do
    StatsMessagesPipeline.call(%MessageData{current_user: user})
  end

  def call(%MessageData{message: "/add" <> _rest = message, current_user: user}) do
    AddTransactionPipeline.call(%MessageData{message: message, current_user: user})
  end

  def call(%MessageData{message: _message} = message_data) do
    message_data
  end
end
