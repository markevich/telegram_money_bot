defmodule TelegramMoneyBot.Steps.Telegram.SendMessage do
  def call(
        %{output_message: output_message, reply_markup: reply_markup, current_user: current_user} =
          payload
      ) do
    {:ok, _} =
      Nadia.send_message(current_user.telegram_chat_id, output_message,
        reply_markup: reply_markup,
        parse_mode: "Markdown"
      )

    payload
  end

  def call(%{output_message: output_message, current_user: current_user} = payload) do
    {:ok, _} =
      Nadia.send_message(current_user.telegram_chat_id, output_message, parse_mode: "Markdown")

    payload
  end

  def call(%{output_message: output_message, chat_id: chat_id} = payload) do
    {:ok, _} = Nadia.send_message(chat_id, output_message, parse_mode: "Markdown")

    payload
  end
end
