defmodule MarkevichMoney.Pipelines.Reports.ComparedExpenses do
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Transactions

  def call do
    user = MarkevichMoney.Users.get_user!(1)
    previous_month = Timex.shift(Timex.now(), months: -1)

    stats_previous_month =
      Transactions.stats(
        user,
        Timex.beginning_of_month(previous_month),
        Timex.end_of_month(previous_month)
      )

    two_month_ago = Timex.shift(Timex.now(), months: -2)

    stats_two_month_ago =
      Transactions.stats(
        user,
        Timex.beginning_of_month(two_month_ago),
        Timex.end_of_month(two_month_ago)
      )

    previous_month =
      stats_previous_month
      |> Enum.map(fn row ->
        row
        |> Map.put(:sum_previous_month, Decimal.abs(row.sum))
        |> Map.put(:sum_two_month_ago, Decimal.new(0))
        |> Map.delete(:sum)
      end)

    union =
      stats_two_month_ago
      |> Enum.reduce(previous_month, fn row, acc ->
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

    union =
      union
      |> Enum.map(fn row ->
        diff = Decimal.sub(row.sum_previous_month, row.sum_two_month_ago)

        row
        |> Map.put(:diff, diff)
      end)
      |> Enum.group_by(fn row ->
        %{
          folder_name: row.folder_name,
          folder_with_single_category: row.folder_with_single_category
        }
      end)
      |> Enum.map(fn {folder, categories} ->
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
      |> Enum.sort_by(fn {folder, _categories} -> Decimal.to_float(folder.diff) end, :desc)

    output =
      Enum.reduce(union, [], fn {folder, categories}, acc ->
        if folder.folder_with_single_category do
          acc ++
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
        else
          diff = symbolic_diff(folder.diff)

          acc =
            acc ++
              [
                [
                  folder.folder_name,
                  folder.sum_two_month_ago,
                  folder.sum_previous_month,
                  diff
                ]
              ]

          sorted =
            Enum.sort_by(categories, fn category -> Decimal.to_float(category.diff) end, :desc)

          rendered =
            Enum.flat_map(sorted, fn category ->
              diff = symbolic_diff(category.diff)

              if List.last(sorted) == category do
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

          acc ++ rendered
        end
      end)

    table =
      output
      |> TableRex.Table.new(["Категория", "06.2021", "07.2021", "Разница"], "Сравнение расходов")
      |> TableRex.Table.put_column_meta(:all, align: :left, padding: 0)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    %{
      current_user: user,
      output_message: """
      ```

      #{table}

      ```
      """
    }
    |> SendMessage.call()
  end

  defp symbolic_diff(value) do
    if Decimal.gt?(value, 0) do
      "🔴+#{value}"
    else
      "🟢#{value}"
    end
  end
end
