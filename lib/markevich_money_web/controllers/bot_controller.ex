defmodule MarkevichMoneyWeb.BotController do
  use MarkevichMoneyWeb, :controller
  alias MarkevichMoney.{CallbackData, MessageData, Pipelines}

  action_fallback MarkevichMoneyWeb.FallbackController

  # Nadia.set_webhook(url: "https://94ba2026.ngrok.io/api/bot/message")

  def webhook(conn, %{"callback_query" => %{"data" => callback_data, "id" => callback_id}}) do
    callback_data = Jason.decode!(callback_data)

    %CallbackData{data: callback_data, id: callback_id}
    |> Pipelines.call()

    json(conn, %{})
  end

  def webhook(conn, %{"message" => %{"text" => input_message}}) do
    %MessageData{message: input_message}
    |> Pipelines.call()

    json(conn, %{})
  end
end
