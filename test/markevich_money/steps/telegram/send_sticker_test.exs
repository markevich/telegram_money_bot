defmodule MarkevichMoney.Steps.Telegram.SendStickerTest do
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.Steps.Telegram.SendSticker

  describe "with success nadia response" do
    defmock Nadia do
      def send_sticker(_chat_id, _file_id, _opts) do
        {:ok, nil}
      end
    end

    mocked_test "returns success payload" do
      payload = %{chat_id: "Hello", file_id: "123", disable_notification: true}

      assert SendSticker.call(payload) == payload
    end
  end
end
