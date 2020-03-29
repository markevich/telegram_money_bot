defmodule MarkevichMoney.Pipelines.HelpTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "/help message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        {:ok, nil}
      end
    end

    mocked_test "Renders help message", %{user: user} do
      expected_message = """
      Я создан помогать следить за расходами.

      */add 10 Еда* - Добавить собственный расход
      */limits* - Просмотр списка всех лимитов по категориям
      */set_limit 1 100* - Установить на категорию с ID 1 лимит в 100
      */stats* - Статистика
      */help* - Диалог помощи
      """

      Pipelines.call(%MessageData{message: "/help", chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message, parse_mode: "Markdown")
      )
    end
  end
end
