defmodule MarkevichMoney.Pipelines.Limits.List do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Steps.Limits.Render
  alias MarkevichMoney.Steps.Telegram.SendMessage

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
