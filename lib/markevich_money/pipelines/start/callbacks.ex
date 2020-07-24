defmodule MarkevichMoney.Pipelines.Start.Callbacks do
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Users
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}

  def call(
        %CallbackData{callback_data: %{"action" => "create_user", "pipeline" => "start"}} =
          callback_data
      ) do
    user =
      %{
        name: username(callback_data.from),
        telegram_chat_id: callback_data.chat_id
      }
      |> Users.upsert_user!()

    callback_data
    |> Map.put(:output_message, output_message(user.notification_email))
    |> SendMessage.call()
    |> AnswerCallback.call()
  end

  defp username(from) do
    if Map.has_key?(from, "username") do
      from["username"]
    else
      from["first_name"]
    end
  end

  defp output_message(notification_email) do
    """
    *#{notification_email}@gmail.com*
    https://survey-ru.com/sayty_oprosov/askgfk.ru_glavnaja.png
    """
  end
end
