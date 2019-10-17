defmodule MarkevichMoney.Steps.Telegram.AnswerCallback do
  def call(%{callback_id: callback_id, output_message: output_message} = payload) do
    Nadia.answer_callback_query(callback_id, text: output_message)

    payload
  end
end
