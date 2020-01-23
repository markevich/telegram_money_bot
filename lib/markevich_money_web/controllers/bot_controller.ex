defmodule MarkevichMoneyWeb.BotController do
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
    %MessageData{message: input_message, chat_id: chat_id}
    |> Pipelines.call()

    json(conn, %{})
  end

  def webhook(conn, _params) do
    json(conn, %{})
  end
end
