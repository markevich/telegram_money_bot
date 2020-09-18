defmodule TelegramMoneyBot.Steps.Telegram.UpdateMessage do
  def call(
        %{
          message_id: message_id,
          output_message: output_message,
          reply_markup: reply_markup,
          chat_id: chat_id
        } = payload
      ) do
    {:ok, _} =
      Nadia.edit_message_text(
        chat_id,
        message_id,
        "",
        output_message,
        reply_markup: reply_markup,
        parse_mode: "Markdown"
      )

    payload
  end

  def call(%{message_id: message_id, output_message: output_message, chat_id: chat_id} = payload) do
    {:ok, _} =
      Nadia.edit_message_text(chat_id, message_id, "", output_message, parse_mode: "Markdown")

    payload
  end
end
