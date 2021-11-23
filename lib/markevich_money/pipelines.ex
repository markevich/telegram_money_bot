defmodule MarkevichMoney.Pipelines do
  use MarkevichMoney.Constants
  use MarkevichMoney.LoggerWithSentry

  alias MarkevichMoney.{CallbackData, MessageData}
  alias MarkevichMoney.Pipelines.AddTransaction, as: AddTransactionPipeline
  alias MarkevichMoney.Pipelines.Categories.Callbacks, as: CategoriesCallbacksPipeline
  alias MarkevichMoney.Pipelines.DeleteTransaction, as: DeleteTransactionPipeline
  alias MarkevichMoney.Pipelines.EditDescription, as: EditDescriptionPipeline
  alias MarkevichMoney.Pipelines.Help.Callbacks, as: HelpCallbacksPipeline
  alias MarkevichMoney.Pipelines.Help.Messages, as: HelpMessagesPipeline
  alias MarkevichMoney.Pipelines.Limits.Callbacks, as: LimitsCallbacksPipeline
  alias MarkevichMoney.Pipelines.Limits.Callbacks, as: LimitsCallbacksPipeline
  alias MarkevichMoney.Pipelines.Limits.Messages, as: LimitsMessagesPipeline
  alias MarkevichMoney.Pipelines.ReceiveTransaction, as: ReceiveTransactionPipeline
  alias MarkevichMoney.Pipelines.RerenderTransaction, as: RerenderTransactionPipeline
  alias MarkevichMoney.Pipelines.Start.Callbacks, as: StartCallbacksPipeline
  alias MarkevichMoney.Pipelines.Start.Messages, as: StartMessagesPipeline
  alias MarkevichMoney.Pipelines.Stats.Callbacks, as: StatsCallbacksPipeline
  alias MarkevichMoney.Pipelines.Stats.Messages, as: StatsMessagesPipeline
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Users

  def call(%CallbackData{callback_data: %{"pipeline" => @start_callback}} = callback_data) do
    StartCallbacksPipeline.call(callback_data)
  end

  def call(%CallbackData{chat_id: chat_id, current_user: nil} = callback_data)
      when is_integer(chat_id) do
    user = Users.get_user_by_chat_id!(chat_id)

    call(%CallbackData{callback_data | current_user: user})
  end

  def call(%CallbackData{callback_data: %{"pipeline" => pipeline}} = callback_data)
      when pipeline in [@choose_category_folder_callback, @set_category_or_folder_callback] do
    callback_data
    |> CategoriesCallbacksPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => @stats_callback}} = callback_data) do
    callback_data
    |> StatsCallbacksPipeline.call()
  end

  def call(
        %CallbackData{callback_data: %{"pipeline" => @delete_transaction_callback}} =
          callback_data
      ) do
    callback_data
    |> DeleteTransactionPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => @limits_stats_callback}} = callback_data) do
    callback_data
    |> LimitsCallbacksPipeline.call()
  end

  def call(
        %CallbackData{callback_data: %{"pipeline" => @rerender_transaction_callback}} =
          callback_data
      ) do
    callback_data
    |> RerenderTransactionPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => @help_callback}} = callback_data) do
    callback_data
    |> HelpCallbacksPipeline.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => _}} = callback_data) do
    callback_data
  end

  def call(%MessageData{current_user: nil, notification_email: notification_email} = message_data)
      when is_binary(notification_email) do
    user = Users.get_user_by_notification_email(notification_email)

    if user do
      call(%MessageData{message_data | current_user: user})
    else
      log_error_message(
        """
          Received email from unknown user.
        """,
        %{unknown_email: notification_email}
      )

      message_data
    end
  end

  def call(%MessageData{message: @start_message, chat_id: _chat_id} = message_data) do
    StartMessagesPipeline.call(message_data)
  end

  def call(%MessageData{current_user: nil, chat_id: chat_id} = message_data)
      when is_integer(chat_id) do
    user = Users.get_user_by_chat_id(chat_id)

    if user do
      call(%MessageData{message_data | current_user: user})
    else
      SendMessage.call(%{
        output_message: "Бот не настроен. Введите команду `/start` чтобы приступить к настройке.",
        chat_id: chat_id
      })
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

  def call(%MessageData{message: @help_message <> _rest, current_user: user}) do
    HelpMessagesPipeline.call(%MessageData{current_user: user})
  end

  def call(%MessageData{message: @stats_message <> _rest, current_user: user}) do
    StatsMessagesPipeline.call(%MessageData{current_user: user})
  end

  def call(%MessageData{message: @add_message <> _rest = message, current_user: user}) do
    AddTransactionPipeline.call(%MessageData{message: message, current_user: user})
  end

  def call(%MessageData{message: @limits_message <> _rest, current_user: _user} = data) do
    LimitsMessagesPipeline.call(data)
  end

  def call(%MessageData{message: @limit_message <> _rest, current_user: _user} = data) do
    LimitsMessagesPipeline.call(data)
  end

  def call(%MessageData{reply_to_message: parent_message} = data)
      when is_binary(parent_message) do
    EditDescriptionPipeline.call(data)
  end

  def call(%MessageData{message: _message} = message_data) do
    message_data
  end
end
