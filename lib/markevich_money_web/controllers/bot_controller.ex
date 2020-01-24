defmodule MarkevichMoneyWeb.BotController do
  require Logger
  use MarkevichMoneyWeb, :controller
  alias MarkevichMoney.{CallbackData, MessageData, Pipelines}

  action_fallback MarkevichMoneyWeb.FallbackController

  def webhook(conn, %{
        "callback_query" => %{
          "data" => callback_data,
          "id" => callback_id,
          "message" => %{
            "message_id" => message_id,
            "text" => message_text,
            "chat" => %{"id" => chat_id}
          }
        }
      }) do
    callback_data = Jason.decode!(callback_data)

    %CallbackData{
      chat_id: chat_id,
      callback_data: callback_data,
      callback_id: callback_id,
      message_id: message_id,
      message_text: message_text
    }
    |> Pipelines.call()

    json(conn, %{})
  end

  def webhook(
        conn,
        %{"message" => %{"text" => input_message, "chat" => %{"id" => chat_id}}}
      ) do
    try do
      %MessageData{message: input_message, chat_id: chat_id}
      |> Pipelines.call()
    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        message = "Случилось что то страшное и я не смог обработать запрос. Детали в логах"

        MarkevichMoney.Steps.Telegram.SendMessage.call(%{
          output_message: message,
          chat_id: chat_id
        })
    end

    json(conn, %{})
  end

  def webhook(conn, _params) do
    json(conn, %{})
  end
end
