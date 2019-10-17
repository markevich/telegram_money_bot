defmodule MarkevichMoney.Pipelines.Compliment do
  alias MarkevichMoney.Steps.Compliment.{FetchCompliments, ChooseRandomCompliment}
  alias MarkevichMoney.Steps.Telegram.{SendMessage, AnswerCallback}

  def call(payload) do
    payload
    |> FetchCompliments.call()
    |> ChooseRandomCompliment.call()
    |> SendMessage.call()
    |> AnswerCallback.call()
  end
end
