defmodule MarkevichMoney.Pipelines.Help.Messages do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Привет! Нужна помощь по какому-то вопросу? Жми кнопку с интересующей тебя темой!
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> Map.put(:reply_markup, render_buttons())
    |> SendMessage.call()
  end

  defp render_buttons do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "🤔 Я новенький, помогите разобраться!",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_newby
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "📲 Как добавить трату вручную?",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_add
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "📈 Как посмотреть статистику?",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_stats
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "📝 Как добавить описание транзакции?",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_edit_description
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "✋ Работа с лимитами.",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_limits
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "🆘 Поддержка.",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_support
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "🐞 Сообщить об ошибке.",
            callback_data:
              Jason.encode!(%{
                pipeline: @help_callback,
                type: @help_callback_bug
              })
          }
        ]
      ]
    }
  end
end
