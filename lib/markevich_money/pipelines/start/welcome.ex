defmodule MarkevichMoney.Pipelines.Start.Welcome do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Привет!
  Я бот, созданный для решения двух важных вопросов: "На что потрачены мои деньги?" и "Как оптимизировать расходы?"

  Позволь сказать пару слов о политике приватности и условиях использования бота:
  - Бот был, есть и навсегда останется бесплатным для тебя;
  - Бот никогда не будет иметь прямого или косвенного доступа к твоему банковскому счёту;
  - Бот работает только с теми данными, к которым ты сам откроешь доступ;
  - Ты в любой момент, без объяснения причины, можешь отключить бота;
  - Бот использует все современные технологии для защиты личных данных пользователя;
  - Личные данные пользователя *никогда* не будут переданы сторонним лицам или организациям;
  - Исходный код бота доступен публично - [https://github.com/markevich/telegram_money_bot](https://github.com/markevich/telegram_money_bot)

  Прежде чем начать, давай убедимся что *все* условия для использования бота соблюдены:
  - Ты являешься жителем Республики Беларусь;
  - У тебя есть счет в "Альфа-Банк";
  - У тебя есть доступ к своему мобильному телефону.

  Теперь ты можешь приступить к настройке бота.

  Нажми на кнопку ниже, чтобы продолжить!
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> put_reply_markup()
    |> SendMessage.call(disable_web_page_preview: true)
  end

  defp put_reply_markup(payload) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Приступить к настройке.",
            callback_data: Jason.encode!(%{pipeline: @start_callback})
          }
        ]
      ]
    }

    payload
    |> Map.put(:reply_markup, reply_markup)
  end
end
