defmodule MarkevichMoneyWeb.BotController do
  use MarkevichMoneyWeb, :controller
  alias MarkevichMoney.{CallbackData, MessageData, Pipelines}

  action_fallback MarkevichMoneyWeb.FallbackController

  def webhook(conn, %{
        "callback_query" => %{
          "data" => callback_data,
          "id" => callback_id,
          "message" => %{"message_id" => message_id, "text" => message_text}
        }
      }) do
    callback_data = Jason.decode!(callback_data)

    %CallbackData{
      callback_data: callback_data,
      callback_id: callback_id,
      message_id: message_id,
      message_text: message_text
    }
    |> Pipelines.call()

    json(conn, %{})
  end

  def webhook(conn, %{"message" => %{"text" => input_message}}) do
    %MessageData{message: input_message}
    |> Pipelines.call()

    json(conn, %{})
  end

  def webhook(conn, _params) do
    json(conn, %{})
  end
end
