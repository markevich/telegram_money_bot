defmodule MarkevichMoney.Pipelines.Compliment do
  alias MarkevichMoney.Steps.Compliment.{ChooseRandomCompliment, FetchCompliments}
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}

  def call(callback_data) do
    callback_data
    |> Map.from_struct()
    |> FetchCompliments.call()
    |> ChooseRandomCompliment.call()
    |> SendMessage.call()
    |> AnswerCallback.call()
  end
end
