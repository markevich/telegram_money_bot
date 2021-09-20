defmodule MarkevichMoney.Pipelines.Reports.ComparedExpenses do
  use MarkevichMoney.Constants

  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Transactions

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

    diff =
      if sum_a >= sum_b do
        Decimal.sub(sum_b, sum_a)
      else
        Decimal.sub(sum_a, sum_b)
      end

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

    payload
    |> Map.put(:sum_a, sum_a)
    |> Map.put(:sum_b, sum_b)
    |> Map.put(:percentage_diff, diff_in_percentage)
    |> Map.put(:numeric_diff, integer_diff)
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
                  row.sum_a,
                  row.sum_b,
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
                  folder.sum_a,
                  folder.sum_b,
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
                    category.sum_a,
                    category.sum_b,
                    diff
                  ],
                  ["", "", "", ""]
                ]
              else
                [
                  [
                    "├#{category.category_name}",
                    category.sum_a,
                    category.sum_b,
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
    ```

    #{payload.table_output}

    Подведем итоги:

    #{payload.stats_a_label} - #{payload.sum_a}
    #{payload.stats_b_label} - #{payload.sum_b}
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
