defmodule MarkevichMoney.Pipelines.Stats.ByCategory do
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}
  alias MarkevichMoney.Transactions

  def call(payload) do
    payload
    |> put_stats()
    |> put_category()
    |> put_stats_total()
    |> put_output_message()
    |> SendMessage.call()
    |> AnswerCallback.call()
  end

  defp put_stats(
         %{
           stat_from: stat_from,
           stat_to: stat_to,
           current_user: current_user,
           callback_data: %{"c_id" => category_id}
         } = payload
       ) do
    Map.put(
      payload,
      :stats,
      Transactions.stats(current_user, stat_from, stat_to, category_id)
    )
  end

  defp put_category(%{callback_data: %{"c_id" => nil}} = payload) do
    Map.put(payload, :transaction_category, %{name: "❓Без категории"})
  end

  defp put_category(%{callback_data: %{"c_id" => category_id}} = payload) do
    Map.put(payload, :transaction_category, Transactions.get_category!(category_id))
  end

  defp put_stats_total(%{stats: stats} = payload) do
    total =
      stats
      |> Enum.reduce(0, fn {_to, amount, _issued_at}, acc ->
        acc + abs(Decimal.to_float(amount))
      end)

    Map.put(payload, :stats_total, total)
  end

  defp put_output_message(%{stats: stats, stat_from: stat_from, stat_to: stat_to} = payload)
       when stats == [] do
    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    payload
    |> Map.put(:output_message, "Отсутствуют транзакции за период с #{from} по #{to}.")
  end

  defp put_output_message(
         %{
           stats: stats,
           stat_from: stat_from,
           stat_to: stat_to,
           transaction_category: transaction_category,
           stats_total: stats_total
         } = payload
       ) do
    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    table =
      stats
      |> Enum.map(fn {to, amount, issued_at} ->
        number = amount |> Decimal.to_float() |> abs() |> Float.ceil(2)
        issued_at = Timex.format!(issued_at, "{0D}.{0M} {h24}:{m}")
        [number, to, issued_at]
      end)
      |> TableRex.Table.new([], "")
      |> TableRex.Table.put_column_meta(:all, align: :left, padding: 1)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    message = """
    Расходы "#{transaction_category.name}" c `#{from}` по `#{to}`:
    ```
      Всего: #{Float.ceil(stats_total, 2)}

    #{table}
    ```
    """

    Map.put(payload, :output_message, message)
  end
end
