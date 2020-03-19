defmodule MarkevichMoney.Pipelines.Stats.Messages do
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Steps.Telegram.SendMessage

  def call(%MessageData{} = payload) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Текущая неделя",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :c_week})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "Текущий месяц",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :c_month})
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Прошлый месяц",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :p_month})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "За все время",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :all})
          }
        ]
      ]
    }

    payload
    |> Map.put(:output_message, "Выберите тип")
    |> Map.put(:reply_markup, reply_markup)
    |> SendMessage.call()
  end
end
