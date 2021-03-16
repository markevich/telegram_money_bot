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
