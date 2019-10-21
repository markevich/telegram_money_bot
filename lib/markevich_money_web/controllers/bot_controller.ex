defmodule MarkevichMoneyWeb.BotController do
  use MarkevichMoneyWeb, :controller
  alias MarkevichMoney.{CallbackData, MessageData, Pipelines}

  action_fallback MarkevichMoneyWeb.FallbackController

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

  def webhook(conn, _params) do
    json(conn, %{})
  end
end
