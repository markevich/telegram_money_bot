defmodule TelegramMoneyBot.Pipelines.Categories.Callbacks do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.CallbackData
  alias TelegramMoneyBot.Pipelines.Categories.{ChooseForTransaction, SetForTransaction}

  def call(
        %CallbackData{callback_data: %{"pipeline" => @choose_category_callback}} = callback_data
      ) do
    callback_data
    |> ChooseForTransaction.call()
  end

  def call(%CallbackData{callback_data: %{"pipeline" => @set_category_callback}} = callback_data) do
    callback_data
    |> SetForTransaction.call()
  end
end
