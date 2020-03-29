defmodule MarkevichMoney.Pipelines.Limits.Messages do
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines.Limits.List
  alias MarkevichMoney.Pipelines.Limits.Set

  def call(%MessageData{message: "/limits"} = message_data) do
    List.call(message_data)
  end

  def call(%MessageData{message: "/set_limit" <> _rest} = message_data) do
    Set.call(message_data)
  end
end
