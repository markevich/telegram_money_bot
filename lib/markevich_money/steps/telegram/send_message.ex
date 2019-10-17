defmodule MarkevichMoney.Steps.Telegram.SendMessage do
  def call(%{output_message: output_message, reply_markup: reply_markup} = payload) do
    Nadia.send_message(-371_960_187, output_message, reply_markup: reply_markup)

    payload
  end

  def call(%{output_message: output_message} = payload) do
    Nadia.send_message(-371_960_187, output_message)

    payload
  end
end
