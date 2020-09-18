defmodule TelegramMoneyBot.Pipelines.Limits.Messages do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.MessageData
  alias TelegramMoneyBot.Pipelines.Limits.List
  alias TelegramMoneyBot.Pipelines.Limits.Set

  def call(%MessageData{message: @limits_message} = message_data) do
    List.call(message_data)
  end

  def call(%MessageData{message: @set_limit_message <> _rest} = message_data) do
    Set.call(message_data)
  end
end
