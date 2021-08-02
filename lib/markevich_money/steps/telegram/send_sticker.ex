defmodule MarkevichMoney.Steps.Telegram.SendSticker do
  def call(
        %{
          file_id: file_id,
          chat_id: chat_id,
          disable_notification: disable_notification
        } = payload
      )
      when not is_nil(chat_id) and not is_nil(file_id) do
    {:ok, _} = Nadia.send_sticker(chat_id, file_id, disable_notification: disable_notification)

    payload
  end
end
