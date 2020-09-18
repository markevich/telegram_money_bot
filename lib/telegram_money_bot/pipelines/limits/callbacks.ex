defmodule TelegramMoneyBot.Pipelines.Limits.Callbacks do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.CallbackData
  alias TelegramMoneyBot.Pipelines.Limits.Stats

  def call(%CallbackData{callback_data: %{"pipeline" => @limits_stats_callback}} = callback_data) do
    callback_data
    |> Stats.call()
  end
end
