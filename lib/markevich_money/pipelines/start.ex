defmodule MarkevichMoney.Pipelines.Start do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message "Выберите дальнейшее действие"

  @callback_data Jason.encode!(%{pipeline: :compliment})

  @reply_markup %Nadia.Model.InlineKeyboardMarkup{
    inline_keyboard: [
      [
        %Nadia.Model.InlineKeyboardButton{
          text: "Сделать комплимент Варе",
          callback_data: @callback_data
        }
      ]
    ]
  }

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> Map.put(:reply_markup, @reply_markup)
    |> SendMessage.call()
  end
end
