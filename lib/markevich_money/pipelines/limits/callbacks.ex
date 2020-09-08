defmodule MarkevichMoney.Pipelines.Limits.Callbacks do
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines.Limits.Stats

  def call(%CallbackData{callback_data: %{"pipeline" => @limits_stats_callback}} = callback_data) do
    callback_data
    |> Stats.call()
  end
end
