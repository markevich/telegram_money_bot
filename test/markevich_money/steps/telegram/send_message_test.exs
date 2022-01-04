defmodule MarkevichMoney.Steps.Telegram.SendMessageTest do
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.Steps.Telegram.SendMessage

  import ExUnit.CaptureLog

  describe "with success nadia response" do
    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end
    end

    mocked_test "returns success payload" do
      payload = %{output_message: "Hello", chat_id: "123"}

      assert SendMessage.call(payload) == payload
    end
  end

  describe "with message longer that 4096 characters" do
    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end
    end

    setup do
      string = "first part of the long message\n"
      first_part = String.duplicate(string, 132)
      second_part = string
      output_message = first_part <> second_part
      telegram_opts = [parse_mode: "Markdown", foo: :bar]

      %{
        first_part: first_part,
        second_part: second_part,
        output_message: output_message,
        telegram_opts: telegram_opts
      }
    end

    mocked_test "sends two messages", context do
      payload = %{output_message: context.output_message, chat_id: "123"}

      SendMessage.call(payload, context.telegram_opts)

      assert_called(
        Nadia.send_message(
          "123",
          context.first_part,
          parse_mode: "Markdown"
        )
      )

      assert_called(
        Nadia.send_message(
          "123",
          context.second_part,
          context.telegram_opts
        )
      )
    end
  end

  describe "with 'Forbidden: user is deactivated' nadia response" do
    defmock Nadia do
      def send_message(_chat_id, _messaged, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason: "Forbidden: user is deactivated"
         }}
      end
    end

    mocked_test "returns success payload" do
      payload = %{output_message: "Hello", chat_id: "123"}

      capture_log(fn ->
        assert SendMessage.call(payload) == payload
      end) =~ "Telegram user is deactivated."
    end
  end

  describe "with 'Forbidden: bot was blocked by the user' nadia response" do
    defmock Nadia do
      def send_message(_chat_id, _messaged, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason: "Forbidden: bot was blocked by the user"
         }}
      end
    end

    mocked_test "returns success payload" do
      payload = %{output_message: "Hello", chat_id: "123"}

      capture_log(fn ->
        assert SendMessage.call(payload) == payload
      end) =~ "Bot was blocked by the user."
    end
  end

  describe "with 'Bad Request: chat not found' nadia response" do
    defmock Nadia do
      def send_message(_chat_id, _messaged, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason: "Bad Request: chat not found"
         }}
      end
    end

    mocked_test "returns success payload" do
      payload = %{output_message: "Hello", chat_id: "123"}

      capture_log(fn ->
        assert SendMessage.call(payload) == payload
      end) =~ "Telegram user no longer exists."
    end
  end

  describe "with 'Forbidden: the group chat was deleted' nadia response" do
    defmock Nadia do
      def send_message(_chat_id, _messaged, _opts) do
        {:error, %Nadia.Model.Error{reason: "Forbidden: the group chat was deleted"}}
      end
    end

    mocked_test "returns success payload" do
      payload = %{output_message: "Hello", chat_id: "123"}

      capture_log(fn ->
        assert SendMessage.call(payload) == payload
      end) =~ "The group chat was deleted."
    end
  end

  describe "with error nadia response" do
    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:error, "Error reason"}
      end
    end

    mocked_test "raises error" do
      payload = %{output_message: "Hello", chat_id: "123"}

      capture_log(fn ->
        assert_raise RuntimeError, "Error reason", fn ->
          SendMessage.call(payload)
        end
      end) =~ "Received unknown response from nadia."
    end
  end
end
