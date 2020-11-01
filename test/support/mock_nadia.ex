defmodule MarkevichMoney.MockNadia do
  use ExUnit.CaseTemplate

  using do
    quote do
      use MecksUnit.Case

      defmock Nadia, preserve: true do
        def send_message(_chat_id, _message, _opts) do
          {:ok, nil}
        end

        def send_photo(_chat_id, _photo, _opts) do
          {:ok, nil}
        end

        def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
          {:ok, nil}
        end

        def answer_callback_query(_callback_id, _options) do
          {:ok, nil}
        end
      end
    end
  end
end
