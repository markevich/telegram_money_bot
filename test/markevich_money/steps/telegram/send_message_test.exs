defmodule MarkevichMoney.Steps.Telegram.SendMessageTest do
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.Steps.Telegram.SendMessage

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

      assert SendMessage.call(payload) == payload
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

      assert_raise RuntimeError, "Error reason", fn ->
        SendMessage.call(payload)
      end
    end
  end
end
