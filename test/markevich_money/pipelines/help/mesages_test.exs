defmodule MarkevichMoney.Pipelines.Help.MessagesTest do
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
      Привет! Нужна помощь по какому-то вопросу? Жми кнопку с интересующей тебя темой!
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_newby}\"}",
              switch_inline_query: nil,
              text: "🤔 Я новенький, помогите разобраться!",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_add}\"}",
              switch_inline_query: nil,
              text: "📲 Как добавить трату вручную?",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_stats}\"}",
              switch_inline_query: nil,
              text: "📈 Как посмотреть статистику?",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_edit_description}\"}",
              switch_inline_query: nil,
              text: "📝 Как добавить описание транзакции?",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_limits}\"}",
              switch_inline_query: nil,
              text: "✋ Работа с лимитами.",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_support}\"}",
              switch_inline_query: nil,
              text: "🆘 Поддержка.",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@help_callback}\",\"type\":\"#{@help_callback_bug}\"}",
              switch_inline_query: nil,
              text: "🐞 Сообщить об ошибке.",
              url: nil
            }
          ]
        ]
      }

      Pipelines.call(%MessageData{message: @help_message, chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end
end
