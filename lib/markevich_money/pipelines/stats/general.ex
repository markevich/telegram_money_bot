defmodule MarkevichMoney.Pipelines.Stats.General do
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}
  alias MarkevichMoney.Transactions

  def call(payload) do
    payload
    |> put_stats()
    |> put_stats_total()
    |> put_reply_markup()
    |> put_output_message()
    |> SendMessage.call()
    |> AnswerCallback.call()
  end

  defp put_stats(%{stat_from: stat_from, stat_to: stat_to, current_user: current_user} = payload) do
    Map.put(
      payload,
      :stats,
      Transactions.stats(current_user, stat_from, stat_to)
    )
  end

  defp put_stats_total(%{stats: stats} = payload) do
    total =
      stats
      |> Enum.reduce(0, fn {amount, _category_name, _category_id}, acc ->
        acc + abs(Decimal.to_float(amount))
      end)

    Map.put(payload, :stats_total, total)
  end

  defp put_reply_markup(%{callback_data: %{"type" => "all"}} = payload) do
    payload
  end

  defp put_reply_markup(%{stats: stats, callback_data: %{"type" => type}} = payload) do
    keyboard =
      stats
      |> Enum.map(fn {_, category_name, category_id} ->
        %Nadia.Model.InlineKeyboardButton{
          text: category_name,
          callback_data:
            Jason.encode!(%{
              pipeline: "stats",
              type: type,
              c_id: category_id
            })
        }
      end)
      |> Enum.chunk_every(2)

    payload
    |> Map.put(:reply_markup, %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard})
  end

  defp put_output_message(%{stats: stats, stat_from: stat_from, stat_to: stat_to} = payload)
       when stats == [] do
    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    payload
    |> Map.put(:output_message, "Отсутствуют транзакции за период с #{from} по #{to}.")
  end

  defp put_output_message(%{stats: stats, stat_from: stat_from, stat_to: stat_to} = payload) do
    header = ["Всего:", Float.ceil(payload[:stats_total], 2)]

    table =
      stats
      |> Enum.map(fn {amount, category_name, _category_id} ->
        number = amount |> Decimal.to_float() |> abs() |> Float.ceil(2)
        [category_name, number]
      end)
      |> TableRex.Table.new(header)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    result_table = """
    Расходы c `#{from}` по `#{to}`:
    ```

    #{table}
    ```
    Детализированная статистика 👇👇
    """

    Map.put(payload, :output_message, result_table)
  end
end
