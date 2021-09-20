defmodule MarkevichMoney.Pipelines.Reports.MonthlyReportTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  use Oban.Testing, repo: MarkevichMoney.Repo
  use MarkevichMoney.Constants

  alias MarkevichMoney.Pipelines.Reports.MonthlyReport

  defmock MarkevichMoney.Sleeper, preserve: true do
    def sleep() do
      {:ok, nil}
    end
  end

  defmock Nadia, preserve: true do
    def send_message(_chat_id, _message, _opts) do
      {:ok, nil}
    end

    def send_sticker(_chat_id, _file_id, _opts) do
      {:ok, nil}
    end

    def answer_callback_query(_callack_id, _opts) do
      {:ok, nil}
    end
  end

  describe "Calculation message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "Send calculation message", %{user: user} do
      MonthlyReport.call(user.id)

      assert_called(
        Nadia.send_message(
          user.telegram_chat_id,
          "Пришло время посмотреть, как ты тратил золотые в этом месяце! Ну-ка, шо тут у нас...",
          parse_mode: "Markdown"
        )
      )

      assert_called(
        Nadia.send_sticker(
          user.telegram_chat_id,
          Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😐"],
          disable_notification: true
        )
      )

      assert_called(
        Nadia.send_message(
          user.telegram_chat_id,
          "Аббажи ещё чуток...",
          parse_mode: "Markdown",
          disable_notification: true
        )
      )

      assert_called(
        Nadia.send_sticker(
          user.telegram_chat_id,
          Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴🧮"],
          disable_notification: true
        )
      )
    end
  end

  describe "Calculations table" do
    setup do
      user = insert(:user)
      one_month_ago = Timex.shift(Timex.now(), months: -1)
      two_month_ago = Timex.shift(Timex.now(), months: -2)
      three_month_ago = Timex.shift(Timex.now(), months: -3)

      %{
        user: user,
        one_month_ago: one_month_ago,
        two_month_ago: two_month_ago,
        three_month_ago: three_month_ago
      }
    end

    mocked_test "Doesn't render anything if there are no transactions in the past month",
                context do
      insert(:transaction, user: context.user, issued_at: context.two_month_ago)
      insert(:transaction, user: context.user, issued_at: context.three_month_ago)

      assert {:no_transactions, _} = MonthlyReport.call(context.user.id)
    end

    mocked_test "Renders generic stats if there are only past two month transactions exists",
                context do
      insert(:transaction, user: context.user, issued_at: context.one_month_ago)
      insert(:transaction, user: context.user, issued_at: context.two_month_ago)

      assert {:short_report_sent, _} = MonthlyReport.call(context.user.id)
    end

    mocked_test "Renders full report if there are transactions in the past 3 months", context do
      insert(:transaction, user: context.user, issued_at: context.one_month_ago)
      insert(:transaction, user: context.user, issued_at: context.two_month_ago)
      insert(:transaction, user: context.user, issued_at: context.three_month_ago)

      assert {:full_report_sent, _} = MonthlyReport.call(context.user.id)
    end
  end
end
