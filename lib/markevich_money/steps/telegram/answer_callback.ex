defmodule MarkevichMoney.Steps.Telegram.AnswerCallback do
  def call(%{callback_id: callback_id} = payload) do
    try do
      Nadia.answer_callback_query(callback_id, text: "Success")
      # TODO: Add test :)
      # coveralls-ignore-start
    rescue
      _e ->
        # Telegram automatically retries failed requests, but callback expires faster than possible retry time limit.
        nil
    end

    # coveralls-ignore-end

    payload
  end
end
