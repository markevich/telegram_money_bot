defmodule MarkevichMoney.Pipelines.Reports.MonthlyReport.ComparedExpenses do
  use MarkevichMoney.Constants

  def call(stats_a, stats_a_label, stats_b, stats_b_label) do
    payload = %{
      stats_a: stats_a,
      stats_b: stats_b,
      stats_a_label: stats_a_label,
      stats_b_label: stats_b_label
    }

    payload
    |> union_stats_b()
    |> union_stats_a()
    |> inject_diff()
    |> group_by_folders()
    |> inject_folders_sum_and_diffs()
    |> inject_overall_sums()
    |> sort_folders()
    |> sort_categories()
    |> generate_table_data()
    |> generate_table_output()
    |> generate_output_message()
  end

  defp union_stats_a(%{union: union, stats_a: stats} = payload) do
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
            |> Map.put(:sum_a, Decimal.abs(row.sum))

          List.replace_at(acc, index, updated_row)
        else
          new_row =
            row
            |> Map.put(:sum_a, Decimal.abs(row.sum))
            |> Map.put(:sum_b, Decimal.new(0))
            |> Map.delete(:sum)

          [new_row | acc]
        end
      end)

    Map.put(payload, :union, union)
  end

  defp union_stats_b(%{stats_b: stats} = payload) do
    union =
      Enum.map(stats, fn row ->
        row
        |> Map.put(:sum_b, Decimal.abs(row.sum))
        |> Map.put(:sum_a, Decimal.new(0))
        |> Map.delete(:sum)
      end)

    Map.put(payload, :union, union)
  end

  defp inject_diff(%{union: union} = payload) do
    union_with_diff =
      Enum.map(union, fn row ->
        diff = Decimal.sub(row.sum_b, row.sum_a)

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
        sum_a =
          Enum.reduce(categories, Decimal.new(0), fn row, sum ->
            Decimal.add(sum, row.sum_a)
          end)

        sum_b =
          Enum.reduce(categories, Decimal.new(0), fn row, sum ->
            Decimal.add(sum, row.sum_b)
          end)

        sum_of_diff = Decimal.sub(sum_b, sum_a)

        updated_folder =
          folder
          |> Map.put(:sum_a, sum_a)
          |> Map.put(:sum_b, sum_b)
          |> Map.put(:diff, sum_of_diff)

        {
          updated_folder,
          categories
        }
      end)

    Map.put(payload, :union, updated_union)
  end

  defp inject_overall_sums(%{union: union} = payload) do
    sum_b =
      Enum.reduce(union, Decimal.new(0), fn {folder, _categories}, acc ->
        Decimal.add(acc, folder.sum_b)
      end)

    sum_a =
      Enum.reduce(union, Decimal.new(0), fn {folder, _categories}, acc ->
        Decimal.add(acc, folder.sum_a)
      end)

    {numeric_diff, percentage_diff} = calculate_diffs(sum_a, sum_b)

    payload
    |> Map.put(:sum_a, sum_a)
    |> Map.put(:sum_b, sum_b)
    |> Map.put(:percentage_diff, percentage_diff)
    |> Map.put(:numeric_diff, numeric_diff)
  end

  defp calculate_diffs(sum_a, sum_b) when sum_a >= sum_b do
    diff = Decimal.sub(sum_a, sum_b)

    diff_in_percentage =
      diff
      |> Decimal.div(sum_b)
      |> Decimal.mult(100)
      |> Decimal.round()
      |> Decimal.to_integer()

    integer_diff =
      diff
      |> Decimal.round()
      |> Decimal.to_integer()

    {-integer_diff, -diff_in_percentage}
  end

  defp calculate_diffs(sum_a, sum_b) when sum_a < sum_b do
    diff = Decimal.sub(sum_b, sum_a)

    diff_in_percentage =
      diff
      |> Decimal.div(sum_a)
      |> Decimal.mult(100)
      |> Decimal.round()
      |> Decimal.to_integer()

    integer_diff =
      diff
      |> Decimal.round()
      |> Decimal.to_integer()

    {integer_diff, diff_in_percentage}
  end

  defp sort_folders(%{union: union} = payload) do
    updated_union =
      Enum.sort_by(union, fn {folder, _categories} -> folder.diff end, {:desc, Decimal})

    Map.put(payload, :union, updated_union)
  end

  defp sort_categories(%{union: union} = payload) do
    updated_union =
      Enum.map(union, fn {folder, categories} ->
        sorted_categories =
          Enum.sort_by(categories, fn category -> category.diff end, {:desc, Decimal})

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
              diff = row.diff |> Decimal.round(2) |> symbolic_diff()

              [
                [
                  row.category_name,
                  Decimal.round(row.sum_a, 2),
                  Decimal.round(row.sum_b, 2),
                  diff
                ],
                ["", "", "", ""]
              ]
            end)

          acc ++ category_table_row
        else
          diff = folder.diff |> Decimal.round(2) |> symbolic_diff()

          folder_row =
            if Enum.count(categories) > 1 do
              [
                [
                  folder.folder_name,
                  Decimal.round(folder.sum_a, 2),
                  Decimal.round(folder.sum_b, 2),
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
              diff = category.diff |> Decimal.round(2) |> symbolic_diff()

              if List.last(categories) == category do
                [
                  [
                    "└#{category.category_name}",
                    Decimal.round(category.sum_a, 2),
                    Decimal.round(category.sum_b, 2),
                    diff
                  ],
                  ["", "", "", ""]
                ]
              else
                [
                  [
                    "├#{category.category_name}",
                    Decimal.round(category.sum_a, 2),
                    Decimal.round(category.sum_b, 2),
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

  defp generate_table_output(
         %{table_data: table_data, stats_a_label: label_a, stats_b_label: label_b} = payload
       ) do
    table_as_string =
      table_data
      |> TableRex.Table.new(["Категория", label_a, label_b, "Разница"], "Сравнение расходов")
      |> TableRex.Table.put_column_meta(:all, align: :left, padding: 0)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    Map.put(payload, :table_output, table_as_string)
  end

  defp generate_output_message(payload) do
    message = """
    Переверни телефон в альбомный режим для лучшей читабельности!
    ```

    #{payload.table_output}

    Подведем итоги:

    #{payload.stats_a_label} - #{payload.sum_a} золотых.
    #{payload.stats_b_label} - #{payload.sum_b} золотых.
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
