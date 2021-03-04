defmodule MarkevichMoney.Pipelines.Help.CallbacksTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines

  describe "#{@help_callback_newby} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_newby},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end

      def send_photo(_chat_id, _photo) do
        {:ok, nil}
      end
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
      assert_called(Nadia.send_photo(user.telegram_chat_id, _))
    end
  end

  describe "#{@help_callback_add} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_add},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
    end
  end

  describe "#{@help_callback_stats} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_stats},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
    end
  end

  describe "#{@help_callback_edit_description} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_edit_description},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end

      def send_photo(_chat_id, _photo) do
        {:ok, nil}
      end
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
      assert_called(Nadia.send_photo(user.telegram_chat_id, _))
    end
  end

  describe "#{@help_callback_limits} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_limits},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
    end
  end

  describe "#{@help_callback_support} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_support},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
    end
  end

  describe "#{@help_callback_bug} callback" do
    setup do
      user = insert(:user)

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @help_callback, "type" => @help_callback_bug},
        current_user: user,
        chat_id: user.telegram_chat_id
      }

      %{user: user, callback_data: callback_data}
    end

    mocked_test "Renders help message", %{user: user, callback_data: callback_data} do
      Pipelines.call(callback_data)

      assert_called(Nadia.send_message(user.telegram_chat_id, _, parse_mode: "Markdown"))
    end
  end
end
