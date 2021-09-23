defmodule MarkevichMoney.Steps.Telegram.AnswerCallback do
  def call(%{callback_id: callback_id} = payload) do
    try do
      {:ok, _result} = Nadia.answer_callback_query(callback_id, text: "Success")
      # TODO: Add test :)
      # coveralls-ignore-start
    rescue
      _e ->
        # Telegram automatically retries failed requests, but callback expires faster than possible retry time limit.
        IO.puts(
          "AnswerCallback errored out. If you see that in tests - that means the request was not stubbed."
        )

        nil
    end

    # coveralls-ignore-end

    payload
  end
end
