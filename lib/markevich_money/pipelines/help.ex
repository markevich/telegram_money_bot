defmodule MarkevichMoney.Pipelines.Help do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Я создан помогать Маркевичам следить за своим бюджетом

  /start - Начало работы
  /help - Диалог помощи
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> SendMessage.call()
  end
end
