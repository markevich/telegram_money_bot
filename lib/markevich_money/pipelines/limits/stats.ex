defmodule MarkevichMoney.Pipelines.Limits.Stats do
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.Steps.Limits.RenderLimitsStats, as: Render
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}

  def call(%CallbackData{callback_data: %{"pipeline" => @limits_stats_callback}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> fetch_limits()
    |> Render.call()
    |> SendMessage.call()
    |> AnswerCallback.call()
  end

  defp fetch_limits(%{current_user: user} = payload) do
    limits = Gamifications.list_categories_limits(user)

    Map.put(payload, :limits, limits)
  end
end
