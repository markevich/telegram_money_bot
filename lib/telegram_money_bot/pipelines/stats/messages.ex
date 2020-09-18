defmodule TelegramMoneyBot.Pipelines.Stats.Messages do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.MessageData
  alias TelegramMoneyBot.Steps.Telegram.SendMessage

  def call(%MessageData{} = payload) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Текущая неделя",
            callback_data:
              Jason.encode!(%{pipeline: @stats_callback, type: @stats_callback_current_week})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "Текущий месяц",
            callback_data:
              Jason.encode!(%{pipeline: @stats_callback, type: @stats_callback_current_month})
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Прошлый месяц",
            callback_data:
              Jason.encode!(%{pipeline: @stats_callback, type: @stats_callback_previous_month})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "За все время",
            callback_data:
              Jason.encode!(%{pipeline: @stats_callback, type: @stats_callback_lifetime})
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Расходы по лимитам",
            callback_data: Jason.encode!(%{pipeline: @limits_stats_callback})
          }
        ]
      ]
    }

    payload
    |> Map.from_struct()
    |> Map.put(:output_message, "Выберите тип")
    |> Map.put(:reply_markup, reply_markup)
    |> SendMessage.call()
  end
end
