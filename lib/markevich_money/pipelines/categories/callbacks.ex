defmodule MarkevichMoney.Pipelines.Categories.Callbacks do
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines.Categories.{ChooseForTransaction, SetForTransaction}

  def call(
        %CallbackData{callback_data: %{"pipeline" => @choose_category_folder_callback}} =
          callback_data
      ) do
    callback_data
    |> ChooseForTransaction.call()
  end

  def call(
        %CallbackData{callback_data: %{"pipeline" => @set_category_or_folder_callback}} =
          callback_data
      ) do
    callback_data
    |> SetForTransaction.call()
  end
end
