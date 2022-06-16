defmodule MarkevichMoney.Pipelines.Stats.General do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage}
  alias MarkevichMoney.Transactions

  # TODO: refactor that module. The calculation part should be outside
  def call(payload) do
    payload
    |> put_stats()
    |> put_stats_total()
    |> put_output_message()
    |> put_details()
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
      |> Enum.reduce(Decimal.new("0"), fn stat, acc ->
        Decimal.add(acc, Decimal.abs(stat.sum))
      end)

    Map.put(payload, :stats_total, total)
  end

  defp put_details(%{callback_data: %{"type" => @stats_callback_lifetime}} = payload) do
    payload
  end

  defp put_details(%{stats: stats} = payload) when stats == [] do
    payload
  end

  defp put_details(%{stats: stats, callback_data: %{"type" => type}} = payload) do
    keyboard =
      stats
      |> Enum.map(fn stat ->
        %Nadia.Model.InlineKeyboardButton{
          text: stat.category_name,
          callback_data:
            Jason.encode!(%{
              pipeline: @stats_callback,
              type: type,
              c_id: stat.category_id
            })
        }
      end)
      |> Enum.chunk_every(2)

    original_message = payload[:output_message]

    message_with_details = """
    #{original_message}
    Детализированная статистика 👇👇
    """

    payload
    |> Map.put(:reply_markup, %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard})
    |> Map.put(:output_message, message_with_details)
  end

  defp put_output_message(%{stats: stats, stat_from: stat_from, stat_to: stat_to} = payload)
       when stats == [] do
    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    payload
    |> Map.put(:output_message, "Отсутствуют транзакции за период с #{from} по #{to}.")
  end

  defp put_output_message(%{stats: stats, stat_from: stat_from, stat_to: stat_to} = payload) do
    header = ["Всего:", Decimal.round(payload[:stats_total], 2)]

    table =
      stats
      |> prepare_data_for_table()
      |> TableRex.Table.new(header, "")
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    result_table = """
    Расходы c `#{from}` по `#{to}`:
    ```

    #{table}
    ```
    """

    Map.put(payload, :output_message, result_table)
  end

  defp prepare_data_for_table(stats) do
    stats
    |> Enum.group_by(fn stat ->
      %{name: stat.folder_name, has_single_category: stat.folder_with_single_category}
    end)
    |> Enum.map(fn {folder, categories} ->
      sum =
        categories
        |> Enum.map(& &1[:sum])
        |> Enum.reduce(Decimal.new(0), fn num, acc -> Decimal.add(acc, num) end)
        |> Decimal.abs()
        |> Decimal.round(2)

      {
        Map.put(folder, :sum, sum),
        categories
      }
    end)
    |> Enum.sort_by(fn {folder, _categories} -> folder.sum end, {:desc, Decimal})
    |> Enum.reduce([], fn {folder, categories}, acc ->
      if folder.has_single_category do
        acc ++ render_folder_with_single_category(folder, categories)
      else
        acc ++ render_folder_with_multiple_category(folder, categories)
      end
    end)
  end

  defp render_folder_with_single_category(_folder, categories) do
    Enum.map(categories, fn category ->
      number =
        category.sum
        |> Decimal.abs()
        |> Decimal.round(2)

      ["#{category.category_name}", number]
    end)
  end

  defp render_folder_with_multiple_category(folder, categories) do
    acc = []
    acc = acc ++ [["#{folder.name}", "= #{folder.sum}"]]

    sorted =
      Enum.map(categories, fn category ->
        float_sum =
          category.sum
          |> Decimal.abs()
          |> Decimal.round(2)

        Map.put(category, :sum, float_sum)
      end)
      |> Enum.sort_by(fn category -> category.sum end, {:desc, Decimal})

    rendered =
      Enum.map(sorted, fn category ->
        if List.last(sorted) == category do
          [" └#{category.category_name}", category.sum]
        else
          [" ├#{category.category_name}", category.sum]
        end
      end)

    acc ++ rendered
  end
end
