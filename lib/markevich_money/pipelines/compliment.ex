defmodule MarkevichMoney.Pipelines.Compliment do
  alias MarkevichMoney.Steps.Compliment.{ChooseRandomCompliment, FetchCompliments}
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}

  def call(payload) do
    payload
    |> FetchCompliments.call()
    |> ChooseRandomCompliment.call()
    |> SendMessage.call()
    |> AnswerCallback.call()
  end
end
