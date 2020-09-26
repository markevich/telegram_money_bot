defmodule MarkevichMoney.Steps.Telegram.UpdateMessage do
  def call(
        %{
          message_id: message_id,
          output_message: output_message,
          reply_markup: reply_markup,
          chat_id: chat_id
        } = payload
      ) do
    case Nadia.edit_message_text(chat_id, message_id, "", output_message,
           reply_markup: reply_markup,
           parse_mode: "Markdown"
         ) do
      {:ok, _result} ->
        payload

      {:error,
       %Nadia.Model.Error{
         reason:
           "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"
       }} ->
        payload

      {:error, other_reason} ->
        raise RuntimeError, message: other_reason
    end
  end

  def call(%{message_id: message_id, output_message: output_message, chat_id: chat_id} = payload) do
    case Nadia.edit_message_text(chat_id, message_id, "", output_message, parse_mode: "Markdown") do
      {:ok, _result} ->
        payload

      {:error,
       %Nadia.Model.Error{
         reason:
           "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"
       }} ->
        payload

      {:error, other_reason} ->
        raise RuntimeError, message: other_reason
    end
  end
end
