defmodule MarkevichMoney.Pipelines.Start.Welcome do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message """
  Привет!
  Я бот, созданный для решения двух вопросов - "На что потрачены мои деньги?", и "Как оптимизировать расходы?"

  Позвольте сказать пару слов о политике приватности данных и условиях использования:
  - Бот был и навсегда останется бесплатным для вас;
  - Бот никогда не будет иметь прямого или косвенного доступа к вашему банковскому счету;
  - Бот работает только с теми данными, к которым вы сами дадите доступ;
  - Вы в любой момент, без объяснения причин, сможете отключить бота;
  - Бот использует все современные технологии для защиты ваших данных;
  - Ваши данные *никогда* не будут переданы сторонним лицам и организациям;
  - Исходный код бота публично доступен - https://github.com/markevich/telegram_money_bot

  Прежде чем начать, давайте убедимся что *все* условия для использования бота соблюдены:
  - Вы являетесь жителем Республики Беларусь;
  - У вас есть счет в "Альфа Банк";
  - У вас подключен "Интернет Банкинг (click.alfa-bank.by)."

  Нажми на кнопку чтобы продолжить!
  """

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> put_reply_markup()
    |> SendMessage.call()
  end

  defp put_reply_markup(payload) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Приступить к настройке.",
            callback_data: Jason.encode!(%{pipeline: "start", action: "create_user"})
          }
        ]
      ]
    }

    payload
    |> Map.put(:reply_markup, reply_markup)
  end
end
