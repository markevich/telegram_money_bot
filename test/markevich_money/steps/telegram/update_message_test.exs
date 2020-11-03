defmodule MarkevichMoney.Steps.Telegram.UpdateMessageTest do
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.Steps.Telegram.UpdateMessage

  describe "with success nadia response" do
    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:ok, nil}
      end
    end

    mocked_test "without reply markup: returns success payload" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123"}

      assert UpdateMessage.call(payload) == payload
    end

    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:ok, nil}
      end
    end

    mocked_test "with reply markup: returns success payload" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123", reply_markup: %{}}

      assert UpdateMessage.call(payload) == payload
    end
  end

  describe "with 'Message exactly the same' nadia response" do
    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason:
             "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"
         }}
      end
    end

    mocked_test "without reply markup: returns success payload" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123"}

      assert UpdateMessage.call(payload) == payload
    end

    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason:
             "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"
         }}
      end
    end

    mocked_test "with reply markup: returns success payload" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123", reply_markup: %{}}

      assert UpdateMessage.call(payload) == payload
    end
  end

  describe "with 'Forbidden: bot was blocked by the user' nadia response" do
    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason: "Forbidden: bot was blocked by the user"
         }}
      end
    end

    mocked_test "without reply markup: returns success payload" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123"}

      assert UpdateMessage.call(payload) == payload
    end

    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:error,
         %Nadia.Model.Error{
           reason: "Forbidden: bot was blocked by the user"
         }}
      end
    end

    mocked_test "with reply markup: returns success payload" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123", reply_markup: %{}}

      assert UpdateMessage.call(payload) == payload
    end
  end

  describe "with error nadia response" do
    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:error, "Error reason"}
      end
    end

    mocked_test "without reply markup: raises error" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123"}

      assert_raise RuntimeError, "Error reason", fn ->
        UpdateMessage.call(payload)
      end
    end

    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _inline_message_id, _message, _opts) do
        {:error, "Error reason"}
      end
    end

    mocked_test "with reply markup: raises error" do
      payload = %{message_id: 1234, output_message: "Hello", chat_id: "123", reply_markup: %{}}

      assert_raise RuntimeError, "Error reason", fn ->
        UpdateMessage.call(payload)
      end
    end
  end
end
