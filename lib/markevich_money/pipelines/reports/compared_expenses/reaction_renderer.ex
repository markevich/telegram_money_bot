defmodule MarkevichMoney.Pipelines.Reports.ReactionRenderer do
  use MarkevichMoney.LoggerWithSentry

  def render_empty_report_reaction() do
    sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😠"]

    message = """
    Ой, а как так? У тебя ж совсем нет транзакций! А ну-ка бегом регистрироваться! Напиши /start, а я тебе все объясню!
    """

    {:ok, message, sticker_id}
  end

  def render_short_report_reaction() do
    sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]

    message = """
    Мы только начали считать твои расходы, поэтому мне не хватает данных составить полноценный отчет.
    Можем взглянуть пока на что ты тратил золотые недавно. А как только наберется цифр за полных два месяца - тогда и поймём, что с тобой делать: бить клюкой по голове или пощадить.
    """

    {:ok, message, sticker_id}
  end

  def render_full_report_reaction(percentage_diff: percentage, numeric_diff: diff) do
    human_diff = "`#{abs(diff)}(#{abs(percentage)}%)`"

    cond do
      abs(percentage) <= 5 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😐"]

        message = """
        Ни жарко, ни холодно: расходы остались на прежнем уровне, ничего не поменялось.
        Хотя могло быть и лучше. Я то в твои годы уже на паролёт накопил!
        """

        {:ok, message, sticker_id}

      percentage > 5 && percentage <= 15 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😠"]

        message = """
        Пойди-ка сюда, есть разговор!
        Глянь! В этом месяце твои расходы выросли на #{human_diff} золотых.
        Пустяки? Ага, щас! Месяц-другой - и без штанов останешься!
        Мой тебе совет - поумерь пыл и начни следить за своими тратами..
        """

        {:ok, message, sticker_id}

      percentage > 15 && percentage <= 40 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴📉"]

        message = """
        У тебя там в штанах прореха или шо?!
        Иначе, как у тебя в этом месяце утекло аж на #{human_diff} золотых больше, чем в предыдущем?!
        Продолжишь транжирить в том же духе - на себе познаешь мощь моей клюки!
        """

        {:ok, message, sticker_id}

      percentage > 40 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴🤬"]

        message = """
        ТЫ ШО НАТВОРИЛ, БЕСТОЛОЧЬ?!
        Это ж надо было так потратиться! На #{human_diff} золотых больше, чем в прошлом месяце!!!
        Когда жрать нечего будет - ко мне не приходи... Я предупреждал!
        """

        {:ok, message, sticker_id}

      percentage <= -5 && percentage >= -15 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]

        message = """
        Отложишь монетку сегодня - построишь дом завтра!
        Начинать всегда надо с малого. Вот и твои расходы уменьшились на #{human_diff} золотых.
        Хороший старт, хотя мог бы и лучше следить за своими тратами...
        """

        {:ok, message, sticker_id}

      percentage < -15 && percentage >= -40 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]

        message = """
        Отвались моя борода, что я вижу! Неужто кто-то за ум взялся!
        Потратил в этом месяце на #{human_diff} золотых меньше, чем в предыдущем.
        Похвально. Так, гляди, и любимым родственничком станешь!
        """

        {:ok, message, sticker_id}

      percentage < -40 ->
        sticker_id = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]

        message = """
        Думал, на своём веку не поведаю больше чудес, а тут...
        Не такая уж ты и бестолочь, оказывается - сохранил на #{human_diff} золотых больше, чем за месяц до этого.
        Продолжай в том же духе и скоро мы...кхе...ты станешь ещё богаче!
        """

        {:ok, message, sticker_id}

      # coveralls-ignore-start
      true ->
        log_error_message(
          "Received unkown numbers for monthly report reaction renderer.",
          %{
            percentage: percentage,
            numeric_diff: diff
          }
        )

        # coveralls-ignore-stop
    end
  end
end
