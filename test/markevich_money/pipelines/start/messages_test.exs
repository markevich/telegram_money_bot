defmodule MarkevichMoney.Pipelines.Start.MessagesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "/start message" do
    mocked_test "Renders welcome message" do
      expected_message = """
      Я создан помогать следить за расходами.

      */add 10 Еда* - Добавить собственный расход
      */limits* - Просмотр списка всех лимитов по категориям
      */set_limit 1 100* - Установить на категорию с ID 1 лимит в 100
      */stats* - Статистика
      */help* - Диалог помощи
      """

      reply_payload = Pipelines.call(%MessageData{message: "/start", chat_id: 123})

      assert(Map.has_key?(reply_payload, :output_message))
      assert_called(Nadia.send_message(123, expected_message, parse_mode: "Markdown"))
    end
  end
end
