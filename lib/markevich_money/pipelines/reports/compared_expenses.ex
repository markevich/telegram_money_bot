defmodule MarkevichMoney.Pipelines.Reports.ComparedExpenses do
  use MarkevichMoney.Constants

  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.CallbackData

  def call(user_id) do
    user = MarkevichMoney.Users.get_user!(user_id)

    payload = %{
      current_user: user
    }

    payload =
      payload
      |> calculate_previous_month_stats()
      |> calculate_two_month_ago_stats()

    case payload do
      %{stats_previous_month: p_m, stats_two_month_ago: t_m_a}
      when p_m == [] and t_m_a == [] ->
        # Ignore users without any transactions
        {:no_transactions, payload}

      %{stats_two_month_ago: t_m_a} when t_m_a == [] ->
        # Only previous month exists, render generic stats
        callback_data = %CallbackData{
          callback_data: %{"type" => @stats_callback_previous_month},
          current_user: user
        }

        payload =
          callback_data
          # TODO: We are calculating the stats twice.
          # TODO: Make it a non callback function. We have nothing to respond to telegram in that case.
          |> MarkevichMoney.Pipelines.Stats.Callbacks.call()

        {:only_previous_month, payload}

      _ ->
        # We have stats for both periods
        payload =
          payload
          |> union_previous_month()
          |> union_two_month_ago()
          |> inject_diff()
          |> group_by_folders()
          |> inject_folders_sum_and_diffs()
          |> inject_overall_sums()
          |> sort_folders()
          |> sort_categories()
          |> generate_table_data()
          |> generate_table_output()
          |> generate_output_message()
          |> SendMessage.call()

        {:ok, payload}
    end
  end

  defp calculate_previous_month_stats(%{current_user: user} = payload) do
    previous_month = Timex.shift(Timex.now(), months: -1)

    stats_previous_month =
      Transactions.stats(
        user,
        Timex.beginning_of_month(previous_month),
        Timex.end_of_month(previous_month)
      )

    payload
    |> Map.put(:stats_previous_month, stats_previous_month)
  end

  defp calculate_two_month_ago_stats(%{current_user: user} = payload) do
    two_month_ago = Timex.shift(Timex.now(), months: -2)

    stats_two_month_ago =
      Transactions.stats(
        user,
        Timex.beginning_of_month(two_month_ago),
        Timex.end_of_month(two_month_ago)
      )

    payload
    |> Map.put(:stats_two_month_ago, stats_two_month_ago)
  end

  defp union_previous_month(%{stats_previous_month: stats} = payload) do
    union =
      Enum.map(stats, fn row ->
        row
        |> Map.put(:sum_previous_month, Decimal.abs(row.sum))
        |> Map.put(:sum_two_month_ago, Decimal.new(0))
        |> Map.delete(:sum)
      end)

    Map.put(payload, :union, union)
  end

  defp union_two_month_ago(%{union: union, stats_two_month_ago: stats} = payload) do
    union =
      Enum.reduce(stats, union, fn row, acc ->
        index =
          Enum.find_index(acc, fn elem ->
            elem.category_id == row.category_id
          end)

        if index do
          updated_row =
            acc
            |> Enum.at(index)
            |> Map.put(:sum_two_month_ago, Decimal.abs(row.sum))

          List.replace_at(acc, index, updated_row)
        else
          new_row =
            row
            |> Map.put(:sum_two_month_ago, Decimal.abs(row.sum))
            |> Map.put(:sum_previous_month, Decimal.new(0))
            |> Map.delete(:sum)

          [new_row | acc]
        end
      end)

    Map.put(payload, :union, union)
  end

  defp inject_diff(%{union: union} = payload) do
    union_with_diff =
      Enum.map(union, fn row ->
        diff = Decimal.sub(row.sum_previous_month, row.sum_two_month_ago)

        row
        |> Map.put(:diff, diff)
      end)

    Map.put(payload, :union, union_with_diff)
  end

  defp group_by_folders(%{union: union} = payload) do
    grouped_union =
      Enum.group_by(union, fn row ->
        %{
          folder_name: row.folder_name,
          folder_with_single_category: row.folder_with_single_category
        }
      end)

    Map.put(payload, :union, grouped_union)
  end

  defp inject_folders_sum_and_diffs(%{union: union} = payload) do
    updated_union =
      Enum.map(union, fn {folder, categories} ->
        sum_two_month_ago =
          Enum.reduce(categories, Decimal.new(0), fn row, sum ->
            Decimal.add(sum, row.sum_two_month_ago)
          end)

        sum_previous_month =
          Enum.reduce(categories, Decimal.new(0), fn row, sum ->
            Decimal.add(sum, row.sum_previous_month)
          end)

        sum_of_diff = Decimal.sub(sum_previous_month, sum_two_month_ago)

        updated_folder =
          folder
          |> Map.put(:sum_two_month_ago, sum_two_month_ago)
          |> Map.put(:sum_previous_month, sum_previous_month)
          |> Map.put(:diff, sum_of_diff)

        {
          updated_folder,
          categories
        }
      end)

    Map.put(payload, :union, updated_union)
  end

  defp inject_overall_sums(%{union: union} = payload) do
    sum_previous_month =
      Enum.reduce(union, Decimal.new(0), fn {folder, _categories}, acc ->
        Decimal.add(acc, folder.sum_previous_month)
      end)

    sum_two_month_ago =
      Enum.reduce(union, Decimal.new(0), fn {folder, _categories}, acc ->
        Decimal.add(acc, folder.sum_two_month_ago)
      end)

    payload
    |> Map.put(:sum_previous_month, sum_previous_month)
    |> Map.put(:sum_two_month_ago, sum_two_month_ago)
  end

  defp sort_folders(%{union: union} = payload) do
    updated_union =
      Enum.sort_by(union, fn {folder, _categories} -> Decimal.to_float(folder.diff) end, :desc)

    Map.put(payload, :union, updated_union)
  end

  defp sort_categories(%{union: union} = payload) do
    updated_union =
      Enum.map(union, fn {folder, categories} ->
        sorted_categories =
          Enum.sort_by(categories, fn category -> Decimal.to_float(category.diff) end, :desc)

        {
          folder,
          sorted_categories
        }
      end)

    Map.put(payload, :union, updated_union)
  end

  defp generate_table_data(%{union: union} = payload) do
    table_data =
      Enum.reduce(union, [], fn {folder, categories}, acc ->
        if folder.folder_with_single_category do
          category_table_row =
            Enum.flat_map(categories, fn row ->
              diff = symbolic_diff(row.diff)

              [
                [
                  row.category_name,
                  row.sum_two_month_ago,
                  row.sum_previous_month,
                  diff
                ],
                ["", "", "", ""]
              ]
            end)

          acc ++ category_table_row
        else
          diff = symbolic_diff(folder.diff)

          folder_row =
            if Enum.count(categories) > 1 do
              [
                [
                  folder.folder_name,
                  folder.sum_two_month_ago,
                  folder.sum_previous_month,
                  diff
                ]
              ]
            else
              [
                [
                  folder.folder_name,
                  "",
                  "",
                  ""
                ]
              ]
            end

          acc = acc ++ folder_row

          category_row =
            Enum.flat_map(categories, fn category ->
              diff = symbolic_diff(category.diff)

              if List.last(categories) == category do
                [
                  [
                    "└#{category.category_name}",
                    category.sum_two_month_ago,
                    category.sum_previous_month,
                    diff
                  ],
                  ["", "", "", ""]
                ]
              else
                [
                  [
                    "├#{category.category_name}",
                    category.sum_two_month_ago,
                    category.sum_previous_month,
                    diff
                  ]
                ]
              end
            end)

          acc ++ category_row
        end
      end)

    Map.put(payload, :table_data, table_data)
  end

  defp generate_table_output(%{table_data: table_data} = payload) do
    table_as_string =
      table_data
      |> TableRex.Table.new(["Категория", "06.2021", "07.2021", "Разница"], "Сравнение расходов")
      |> TableRex.Table.put_column_meta(:all, align: :left, padding: 0)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    Map.put(payload, :table_output, table_as_string)
  end

  defp generate_output_message(payload) do
    message = """
    ```

    #{payload.table_output}

    Прошлый месяц - #{payload.sum_previous_month}
    Два месяца назад - #{payload.sum_two_month_ago}
    ```
    """

    Map.put(payload, :output_message, message)
  end

  defp symbolic_diff(value) do
    if Decimal.gt?(value, 0) do
      "🔴+#{value}"
    else
      "🟢#{value}"
    end
  end
end
