defmodule MarkevichMoney.Pipelines.Start.CallbacksTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.{CallbackData, Pipelines, Users}

  describe "#{@start_callback} callback" do
    setup do
      chat_id = 483_912_384
      username = "New user name"

      callback_data = %CallbackData{
        callback_data: %{
          "pipeline" => @start_callback
        },
        callback_id: 123,
        chat_id: chat_id,
        from: %{"username" => username, "first_name" => "First name"}
      }

      %{callback_data: callback_data, chat_id: chat_id, username: username}
    end

    defmock MarkevichMoney.Sleeper, preserve: true do
      def sleep do
        {:ok, nil}
      end
    end

    mocked_test "Sends instructions to user", context do
      reply_payload = Pipelines.call(context.callback_data)

      assert(Map.has_key?(reply_payload, :output_message))

      last_user = Users.get_user_by_chat_id(context.chat_id)
      assert(last_user != nil)

      assert(last_user.notification_email =~ "tg.money.bot+")

      assert_called(
        Nadia.send_message(
          context.chat_id,
          _,
          parse_mode: "Markdown"
        )
      )

      assert_called(
        Nadia.answer_callback_query(context.callback_data.callback_id, text: "Успешно")
      )
    end
  end
end
