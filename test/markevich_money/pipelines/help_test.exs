defmodule MarkevichMoney.Pipelines.HelpTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "#{@help_message} message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "Renders help message", %{user: user} do
      expected_message = """
      Я создан помогать следить за расходами.

      *#{@add_message} 10 Еда* - Добавить собственный расход
      *#{@limits_message}* - Просмотр списка всех лимитов по категориям
      *#{@set_limit_message} 1 100* - Установить на категорию с ID 1 лимит в 100
      *#{@stats_message}* - Статистика
      *#{@help_message}* - Диалог помощи
      """

      Pipelines.call(%MessageData{message: @help_message, chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message, parse_mode: "Markdown")
      )
    end
  end
end
