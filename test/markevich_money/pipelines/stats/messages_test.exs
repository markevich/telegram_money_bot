defmodule MarkevichMoney.Pipelines.Stats.MessagesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "#{@stats_message} message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "Renders stats message", %{user: user} do
      expected_message = "Выберите тип"

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_current_week}\"}",
              switch_inline_query: nil,
              text: "Текущая неделя",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_current_month}\"}",
              switch_inline_query: nil,
              text: "Текущий месяц",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_previous_month}\"}",
              switch_inline_query: nil,
              text: "Прошлый месяц",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_lifetime}\"}",
              switch_inline_query: nil,
              text: "За все время",
              url: nil
            }
          ]
        ]
      }

      Pipelines.call(%MessageData{message: @stats_message, chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(
          user.telegram_chat_id,
          expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end
end
