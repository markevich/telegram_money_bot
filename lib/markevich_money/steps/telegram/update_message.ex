defmodule MarkevichMoney.Steps.Telegram.UpdateMessage do
  def call(
        %{message_id: message_id, output_message: output_message, reply_markup: reply_markup} =
          payload
      ) do

    Nadia.edit_message_text(
      -371_960_187,
      message_id,
      nil,
      output_message,
      reply_markup: reply_markup,
      parse_mode: "Markdown"
    )

    payload
  end

  def call(%{message_id: message_id, output_message: output_message} = payload) do
    Nadia.edit_message_text(-371_960_187, message_id, nil, output_message, parse_mode: "Markdown")

    payload
  end
end
