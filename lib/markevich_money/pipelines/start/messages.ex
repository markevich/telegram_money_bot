defmodule MarkevichMoney.Pipelines.Start.Messages do
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines.Start.Welcome

  def call(%MessageData{message: "/start"} = message_data) do
    Welcome.call(message_data)
  end
end
