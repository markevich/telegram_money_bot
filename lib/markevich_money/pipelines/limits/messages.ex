defmodule MarkevichMoney.Pipelines.Limits.Messages do
  use MarkevichMoney.Constants
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines.Limits.List
  alias MarkevichMoney.Pipelines.Limits.Set

  def call(%MessageData{message: @limits_message} = message_data) do
    List.call(message_data)
  end

  def call(%MessageData{message: @limit_message <> _rest} = message_data) do
    Set.call(message_data)
  end
end
