defmodule MarkevichMoney.PipelinesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  import ExUnit.CaptureLog

  describe "unknown callback pipelines" do
    setup do
      user = insert(:user)
      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "_unknown"},
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: ""
      }

      %{callback_data: callback_data}
    end

    test "does nothing", %{callback_data: callback_data} do
      result = Pipelines.call(callback_data)

      assert(result == callback_data)
    end
  end

  describe "message data with notification_email" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "puts current user into payload when user exists", %{user: user} do
      message_data = %MessageData{
        notification_email: user.notification_email,
        message: ""
      }

      result = Pipelines.call(message_data)

      assert(%{current_user: current_user} = result)
      assert(current_user == user)
    end

    test "does nothing but log when user is not exists" do
      message_data = %MessageData{
        notification_email: "_PWNED",
        message: ""
      }

      capture_log(fn ->
        result = Pipelines.call(message_data)

        assert(%{current_user: nil} = result)
      end) =~ "Received email from unknown user"
    end
  end

  describe "message data with chat_id" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "puts current user into payload when user exists", %{user: user} do
      message_data = %MessageData{
        chat_id: user.telegram_chat_id,
        message: ""
      }

      result = Pipelines.call(message_data)

      assert(%{current_user: current_user} = result)
      assert(current_user == user)
    end

    mocked_test "renders unauthorized message when user is not exists" do
      Pipelines.call(%MessageData{chat_id: -1, current_user: nil})

      assert_called(
        Nadia.send_message(
          -1,
          "Бот не настроен. Введите команду `/start` чтобы приступить к настройке.",
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "callback data with chat_id" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "puts current user into payload when user exists", %{user: user} do
      callback_data = %CallbackData{
        chat_id: user.telegram_chat_id,
        callback_data: %{"pipeline" => "_unexisting"}
      }

      result = Pipelines.call(callback_data)

      assert(%{current_user: current_user} = result)
      assert(current_user == user)
    end
  end
end
