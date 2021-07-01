defmodule MarkevichMoney.Steps.Limits.RenderLimitsValues do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Steps.Limits.RenderLimitsStats

  def call(%{limits: limits, current_user: _current_user} = payload) do
    limits_values = render_limits_table(limits)
    limits_stats = RenderLimitsStats.call(payload)[:output_message]

    message = """
    ```

    #{limits_values}
    ```
    #{limits_stats}
    Для установки лимита используйте:

    *#{@limit_message} категория число*
    """

    payload
    |> Map.put(:output_message, message)
  end

  defp render_limits_table(limits) do
    limits
    |> Enum.group_by(fn category -> category.transaction_category_folder end)
    |> Enum.reduce([], fn {folder, categories}, acc ->
      if folder.has_single_category do
        acc ++ render_folder_with_single_category(folder, categories)
      else
        acc ++ render_folder_with_multiple_category(folder, categories)
      end
    end)
    |> TableRex.Table.new(["Категория", "Лимит"], "Лимиты по категориям")
    |> TableRex.Table.put_column_meta(:all, align: :left, padding: 1)
    |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)
  end

  defp render_folder_with_single_category(_folder, categories) do
    Enum.map(categories, fn category ->
      limit = limit_value(category)

      ["#{category.name}", limit]
    end)
  end

  defp render_folder_with_multiple_category(folder, categories) do
    acc = []
    acc = acc ++ [["#{folder.name}", ""]]

    acc ++
      Enum.map(categories, fn category ->
        limit = limit_value(category)

        if List.last(categories) == category do
          [" └#{category.name}", limit]
        else
          [" ├#{category.name}", limit]
        end
      end)
  end

  defp limit_value(category) do
    case category.transaction_category_limit do
      nil -> "♾️"
      # credo:disable-for-next-line
      category_limit -> if category_limit.limit == 0, do: "♾️", else: category_limit.limit
    end
  end
end
