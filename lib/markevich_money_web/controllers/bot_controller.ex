defmodule MarkevichMoneyWeb.BotController do
  use MarkevichMoneyWeb, :controller
  require Logger
  alias MarkevichMoney.{CallbackData, MessageData, Pipelines}
  alias MarkevichMoney.LoggerWithSentry
  alias MarkevichMoney.Steps.Telegram.SendMessage

  action_fallback MarkevichMoneyWeb.FallbackController

  def webhook(conn, %{
        "callback_query" => %{
          "data" => callback_data,
          "id" => callback_id,
          "from" => from,
          "message" => %{
            "message_id" => message_id,
            "text" => message_text,
            "chat" => %{"id" => chat_id}
          }
        }
      }) do
    callback_data = Jason.decode!(callback_data)

    try do
      %CallbackData{
        chat_id: chat_id,
        callback_data: callback_data,
        callback_id: callback_id,
        from: from,
        message_id: message_id,
        message_text: message_text
      }
      |> Pipelines.call()
    rescue
      e ->
        LoggerWithSentry.log_exception(e, __STACKTRACE__, callback_data: callback_data)

        message = "Случилось что то страшное и я не смог обработать запрос."

        SendMessage.call(%{
          output_message: message,
          chat_id: chat_id
        })
    end

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
        LoggerWithSentry.log_exception(e, __STACKTRACE__, input_message: input_message)

        message = "Случилось что то страшное и я не смог обработать запрос."

        SendMessage.call(%{
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
