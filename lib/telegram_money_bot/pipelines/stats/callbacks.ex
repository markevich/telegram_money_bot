defmodule TelegramMoneyBot.Pipelines.Stats.Callbacks do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.CallbackData
  alias TelegramMoneyBot.Pipelines.Stats.{ByCategory, General}

  def call(
        %CallbackData{callback_data: %{"type" => @stats_callback_current_week}} = callback_data
      ) do
    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.shift(Timex.now(), days: -7))
    |> Map.put(:stat_to, Timex.shift(Timex.now(), days: 1))
    |> pcall()
  end

  def call(
        %CallbackData{callback_data: %{"type" => @stats_callback_current_month}} = callback_data
      ) do
    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.beginning_of_month(Timex.now()))
    |> Map.put(:stat_to, Timex.end_of_month(Timex.now()))
    |> pcall()
  end

  def call(
        %CallbackData{callback_data: %{"type" => @stats_callback_previous_month}} = callback_data
      ) do
    previous_month = Timex.shift(Timex.now(), months: -1)

    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.beginning_of_month(previous_month))
    |> Map.put(:stat_to, Timex.end_of_month(previous_month))
    |> pcall()
  end

  def call(%CallbackData{callback_data: %{"type" => @stats_callback_lifetime}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.parse!("2000-01-01T00:00:00+0000", "{ISO:Extended}"))
    |> Map.put(:stat_to, Timex.shift(Timex.now(), days: 1))
    |> pcall()
  end

  defp pcall(%{callback_data: %{"c_id" => _category_id}} = payload) do
    ByCategory.call(payload)
  end

  defp pcall(payload) do
    General.call(payload)
  end
end
