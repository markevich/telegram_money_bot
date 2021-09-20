defmodule MarkevichMoney.Pipelines.Reports.MonthlyReport do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Steps.Telegram.SendSticker
  alias MarkevichMoney.Users
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines.Reports.ComparedExpenses
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Pipelines.Reports.ReactionRenderer
  alias MarkevichMoney.Sleeper

  def call(user_id) do
    user = Users.get_user!(user_id)

    %{
      current_user: user,
      chat_id: user.telegram_chat_id
    }
    |> send_message_about_stats_calculation()
    |> send_message_with_stats()
  end

  def send_message_about_stats_calculation(%{chat_id: chat_id} = payload) do
    # TODO: refactor that sleep immediately! It's time to introduce async message sending for telegram.
    sticker1 = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴😐"]

    SendSticker.call(%{
      chat_id: chat_id,
      file_id: sticker1,
      disable_notification: true
    })

    Sleeper.sleep()

    message1 =
      "Пришло время посмотреть, как ты тратил золотые в этом месяце! Ну-ка, шо тут у нас..."

    SendMessage.call(%{chat_id: chat_id, output_message: message1})

    Sleeper.sleep()

    sticker2 = Application.get_env(:markevich_money, :tg_file_ids)[:stickers][:"👴🧮"]

    SendSticker.call(%{
      chat_id: chat_id,
      file_id: sticker2,
      disable_notification: true
    })

    Sleeper.sleep()

    message2 = "Аббажи ещё чуток..."

    SendMessage.call(%{chat_id: chat_id, output_message: message2},
      disable_notification: true
    )

    Sleeper.sleep()

    payload
  end

  def send_message_with_stats(%{current_user: user}) do
    previous_month = Timex.shift(Timex.now(), months: -1)
    two_month_ago = Timex.shift(Timex.now(), months: -2)
    three_month_ago = Timex.shift(Timex.now(), months: -3)

    monthly_state = transactions_state(user, previous_month, two_month_ago, three_month_ago)

    case monthly_state do
      %{prev_month_exists: true, two_month_ago_exists: true, three_month_ago_exists: true} ->
        {:full_report_sent, send_full_compared_expenses(user, previous_month, two_month_ago)}

      %{prev_month_exists: true} ->
        {:short_report_sent, send_generic_monthly_expenses(user)}

      _ ->
        {:no_transactions, nil}
    end
  end

  def transactions_state(user, prev_month, two_month_ago, three_month_ago) do
    %{
      prev_month_exists: Transactions.exists_in_month?(user.id, prev_month),
      two_month_ago_exists: Transactions.exists_in_month?(user.id, two_month_ago),
      three_month_ago_exists: Transactions.exists_in_month?(user.id, three_month_ago)
    }
  end

  def send_full_compared_expenses(user, previous_month, two_month_ago) do
    stats_previous_month =
      Transactions.stats(
        user,
        Timex.beginning_of_month(previous_month),
        Timex.end_of_month(previous_month)
      )

    stats_two_month_ago =
      Transactions.stats(
        user,
        Timex.beginning_of_month(two_month_ago),
        Timex.end_of_month(two_month_ago)
      )

    payload =
      ComparedExpenses.call(
        stats_two_month_ago,
        Timex.format!(two_month_ago, "{0M}.{YYYY}"),
        stats_previous_month,
        Timex.format!(previous_month, "{0M}.{YYYY}")
      )

    payload
    |> Map.put(:current_user, user)
    |> SendMessage.call()

    Sleeper.sleep()

    {:ok, reaction_message, reaction_sticker} =
      ReactionRenderer.render_full_report_reaction(
        percentage_diff: payload.percentage_diff,
        numeric_diff: payload.numeric_diff
      )

    %{
      chat_id: user.telegram_chat_id,
      file_id: reaction_sticker,
      disable_notification: true
    }
    |> SendSticker.call()

    Sleeper.sleep()

    %{
      chat_id: user.telegram_chat_id,
      output_message: reaction_message
    }
    |> SendMessage.call()

    payload
  end

  def send_generic_monthly_expenses(user) do
    callback_data = %CallbackData{
      callback_data: %{"type" => @stats_callback_previous_month},
      current_user: user
    }

    callback_data
    # TODO: Make it a non callback function. We have nothing to respond to telegram in that case.
    |> MarkevichMoney.Pipelines.Stats.Callbacks.call()
  end
end
