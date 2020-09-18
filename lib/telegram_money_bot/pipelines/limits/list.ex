defmodule TelegramMoneyBot.Pipelines.Limits.List do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.Gamifications
  alias TelegramMoneyBot.MessageData
  alias TelegramMoneyBot.Steps.Limits.RenderLimitsValues, as: Render
  alias TelegramMoneyBot.Steps.Telegram.SendMessage

  def call(%MessageData{message: @limits_message <> _rest} = message_data) do
    message_data
    |> Map.from_struct()
    |> fetch_limits()
    |> Render.call()
    |> SendMessage.call()
  end

  defp fetch_limits(%{current_user: user} = payload) do
    limits = Gamifications.list_categories_limits(user)

    Map.put(payload, :limits, limits)
  end
end
