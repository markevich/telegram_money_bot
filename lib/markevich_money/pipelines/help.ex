defmodule MarkevichMoney.Pipelines.Help do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Я создан помогать следить за расходами.

  *#{@add_message} 10 Еда* - Добавить собственный расход
  *#{@stats_message}* - Статистика
  *#{@limits_message}* - Просмотр списка всех лимитов по категориям
  *#{@limit_message} Еда 100* - Установить на категорию Еда лимит в 100
  *#{@help_message}* - Диалог помощи
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> SendMessage.call()
  end
end
