defmodule MarkevichMoney.Pipelines.Reports.ReactionRendererTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Pipelines.Reports.ReactionRenderer

  describe "render_empty_report_reaction" do
    test "returns correct sticker id and message" do
      {:ok, message, sticker_id} = ReactionRenderer.render_empty_report_reaction()

      assert(
        message == """
        Ой, а как так? У тебя ж совсем нет транзакций! А ну-ка бегом регистрироваться! Напиши /start, а я тебе все объясню!
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😠"]
    end
  end

  describe "render_short_report_reaction" do
    test "returns correct sticker id and message" do
      {:ok, message, sticker_id} = ReactionRenderer.render_short_report_reaction()

      assert(
        message == """
        Мы только начали считать твои расходы, поэтому мне не хватает данных составить полноценный отчет.
        Можем взглянуть пока на что ты тратил золотые недавно. А как только наберется цифр за полных два месяца - тогда и поймём, что с тобой делать: бить клюкой по голове или пощадить.
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]
    end
  end

  describe "render_full_report_reaction" do
    test "when percentage > or < then abs(5)" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: 3,
          numeric_diff: 5
        )

      assert(
        message == """
        Ни жарко, ни холодно: расходы остались на прежнем уровне, ничего не поменялось.
        Хотя могло быть и лучше. Я то в твои годы уже на паролёт накопил!
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😐"]

      {:ok, message2, sticker_id2} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: -4,
          numeric_diff: -5
        )

      assert message2 == message
      assert sticker_id2 == sticker_id
    end

    test "when 5 < percentage < 15" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: 10,
          numeric_diff: 100
        )

      assert(
        message == """
        Пойди-ка сюда, есть разговор!
        Глянь! В этом месяце твои расходы выросли на `100(10%)` золотых.
        Пустяки? Ага, щас! Месяц-другой - и без штанов останешься!
        Мой тебе совет - поумерь пыл и начни следить за своими тратами..
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😠"]
    end

    test "when 15 < percentage <= 40" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: 35,
          numeric_diff: 100
        )

      assert(
        message == """
        У тебя там в штанах прореха или шо?!
        Иначе, как у тебя в этом месяце утекло аж на `100(35%)` золотых больше, чем в предыдущем?!
        Продолжишь транжирить в том же духе - на себе познаешь мощь моей клюки!
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴📉"]
    end

    test "when 40 < percentage" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: 41,
          numeric_diff: 100
        )

      assert(
        message == """
        ТЫ ШО НАТВОРИЛ, БЕСТОЛОЧЬ?!
        Это ж надо было так потратиться! На `100(41%)` золотых больше, чем в прошлом месяце!!!
        Когда жрать нечего будет - ко мне не приходи... Я предупреждал!
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴🤬"]
    end

    test "when -15 < percentage < -5" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: -10,
          numeric_diff: -100
        )

      assert(
        message == """
        Отложишь монетку сегодня - построишь дом завтра!
        Начинать всегда надо с малого. Вот и твои расходы уменьшились на `100(10%)` золотых.
        Хороший старт, хотя мог бы и лучше следить за своими тратами...
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]
    end

    test "when -40 < percentage < -15" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: -35,
          numeric_diff: -100
        )

      assert(
        message == """
        Отвались моя борода, что я вижу! Неужто кто-то за ум взялся!
        Потратил в этом месяце на `100(35%)` золотых меньше, чем в предыдущем.
        Похвально. Так, гляди, и любимым родственничком станешь!
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]
    end

    test "when percentage < -40" do
      {:ok, message, sticker_id} =
        ReactionRenderer.render_full_report_reaction(
          percentage_diff: -55,
          numeric_diff: -100
        )

      assert(
        message == """
        Думал, на своём веку не поведаю больше чудес, а тут...
        Не такая уж ты и бестолочь, оказывается - сохранил на `100(55%)` золотых больше, чем за месяц до этого.
        Продолжай в том же духе и скоро мы...кхе...ты станешь ещё богаче!
        """
      )

      assert sticker_id == Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴👍"]
    end
  end
end
