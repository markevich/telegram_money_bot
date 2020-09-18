defmodule TelegramMoneyBot.Pipelines.Limits.Stats do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.CallbackData
  alias TelegramMoneyBot.Gamifications
  alias TelegramMoneyBot.Steps.Limits.RenderLimitsStats, as: Render
  alias TelegramMoneyBot.Steps.Telegram.{AnswerCallback, SendMessage}

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
