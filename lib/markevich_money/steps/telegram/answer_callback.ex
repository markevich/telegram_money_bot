defmodule MarkevichMoney.Steps.Telegram.AnswerCallback do
  def call(%{callback_id: callback_id} = payload) do
    Nadia.answer_callback_query(callback_id, text: "Success")

    payload
  end
end
