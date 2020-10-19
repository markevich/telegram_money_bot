defmodule MarkevichMoney.Pipelines.Start.MessagesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "#{@start_message} message" do
    mocked_test "Renders welcome message" do
      reply_payload = Pipelines.call(%MessageData{message: @start_message, chat_id: 123})

      assert(Map.has_key?(reply_payload, :output_message))

      assert_called(
        Nadia.send_message(
          123,
          _,
          reply_markup: %Nadia.Model.InlineKeyboardMarkup{
            inline_keyboard: [
              [
                %Nadia.Model.InlineKeyboardButton{
                  callback_data: "{\"pipeline\":\"#{@start_callback}\"}",
                  switch_inline_query: nil,
                  text: "Приступить к настройке.",
                  url: nil
                }
              ]
            ]
          },
          parse_mode: "Markdown"
        )
      )
    end
  end
end
