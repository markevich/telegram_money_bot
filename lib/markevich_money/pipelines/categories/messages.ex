defmodule MarkevichMoney.Pipelines.Categories.Messages do
  alias MarkevichMoney.MessageData

  def call(%MessageData{} = payload) do
    payload
  end
end
