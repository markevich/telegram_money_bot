defmodule MarkevichMoney.Pipelines.Start.CallbacksTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.{CallbackData, Pipelines, Users}

  describe "#{@start_callback} callback with username" do
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

    mocked_test "Sends instructions to user", context do
      reply_payload = Pipelines.call(context.callback_data)

      assert(Map.has_key?(reply_payload, :output_message))

      last_user = Users.get_user_by_chat_id(context.chat_id)
      assert(last_user != nil)

      assert(last_user.name == context.username)

      assert(last_user.notification_email =~ "tg.money.bot+")

      assert_called(
        Nadia.send_message(
          context.chat_id,
          _,
          parse_mode: "Markdown"
        )
      )

      assert_called(
        Nadia.answer_callback_query(context.callback_data.callback_id, text: "Success")
      )
    end
  end

  describe "#{@start_callback} callback with first_name" do
    setup do
      chat_id = 483_912_384
      first_name = "First name"

      callback_data = %CallbackData{
        callback_data: %{
          "pipeline" => @start_callback
        },
        callback_id: 123,
        chat_id: chat_id,
        from: %{"first_name" => first_name}
      }

      %{callback_data: callback_data, chat_id: chat_id, first_name: first_name}
    end

    mocked_test "Sends instructions to user", context do
      reply_payload = Pipelines.call(context.callback_data)

      assert(Map.has_key?(reply_payload, :output_message))

      last_user = Users.get_user_by_chat_id(context.chat_id)
      assert(last_user != nil)

      assert(last_user.name == context.first_name)

      assert(last_user.notification_email =~ "tg.money.bot+")

      assert_called(
        Nadia.send_message(
          context.chat_id,
          "```#{last_user.notification_email}@gmail.com```",
          parse_mode: "Markdown"
        )
      )

      for n <- [1, 2, 3, 4, 5, 6] do
        file_name = String.to_atom("alfa_click_email#{n}")

        instruction_file =
          Application.get_env(:markevich_money, :tg_file_ids)[:user_registration][file_name]

        assert_called(Nadia.send_photo(context.chat_id, instruction_file, _))
      end

      assert_called(
        Nadia.answer_callback_query(context.callback_data.callback_id, text: "Success")
      )
    end
  end
end
