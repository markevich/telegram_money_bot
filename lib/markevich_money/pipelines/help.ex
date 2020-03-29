defmodule MarkevichMoney.Pipelines.Help do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Я создан помогать следить за расходами.

  */add 10 Еда* - Добавить собственный расход
  */limits* - Просмотр списка всех лимитов по категориям
  */set_limit 1 100* - Установить на категорию с ID 1 лимит в 100
  */stats* - Статистика
  */help* - Диалог помощи
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> SendMessage.call()
  end
end
