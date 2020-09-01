defmodule MarkevichMoney.Pipelines.Help do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Я создан помогать следить за расходами.

  *#{@add_message} 10 Еда* - Добавить собственный расход
  *#{@limits_message}* - Просмотр списка всех лимитов по категориям
  *#{@set_limit_message} 1 100* - Установить на категорию с ID 1 лимит в 100
  *#{@stats_message}* - Статистика
  *#{@help_message}* - Диалог помощи
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> SendMessage.call()
  end
end
