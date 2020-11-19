defmodule MarkevichMoney.Steps.Telegram.SendPhoto do
  def call(
        %{
          output_message: output_message,
          output_file_id: file_id,
          chat_id: chat_id
        } = payload
      )
      when not is_nil(chat_id) and not is_nil(file_id) do
    {:ok, _} = Nadia.send_photo(chat_id, file_id, caption: output_message)

    payload
  end

  def call(
        %{
          output_file_id: file_id,
          chat_id: chat_id
        } = payload
      )
      when not is_nil(chat_id) and not is_nil(file_id) do
    {:ok, _} = Nadia.send_photo(chat_id, file_id)

    payload
  end
end
