defmodule MarkevichMoney.Steps.Limits.RenderLimitsStats do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Transactions

  def call(%{limits: limits, current_user: current_user} = payload) do
    limits_stats =
      limits
      |> reject_categories_without_limits()
      |> render_limits_stats(current_user)

    message = """
    ```
    #{limits_stats}
    ```
    """

    payload
    |> Map.put(:output_message, message)
  end

  defp reject_categories_without_limits(limits) do
    limits
    |> Enum.reject(fn category ->
      !category.transaction_category_limit || category.transaction_category_limit.limit == 0
    end)
  end

  defp render_limits_stats(limits, _) when limits == [] do
    "Отсутствуют установленные лимиты"
  end

  defp render_limits_stats(limits, current_user) do
    limits
    |> Enum.group_by(fn category -> category.transaction_category_folder end)
    |> Enum.reduce([], fn {folder, categories}, acc ->
      if folder.has_single_category do
        acc ++ render_folder_with_single_category(current_user, folder, categories)
      else
        acc ++ render_folder_with_multiple_category(current_user, folder, categories)
      end
    end)
    |> TableRex.Table.new(["Категория", "Расходы"], "Расходы за текущий месяц")
    |> TableRex.Table.put_column_meta(:all, align: :left, padding: 1)
    |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)
  end

  defp render_folder_with_single_category(current_user, _folder, categories) do
    Enum.map(categories, fn category ->
      total_spending =
        Transactions.get_category_monthly_spendings(current_user.id, category.id, [])
        |> round()

      limit = limit_value(category)

      ["#{category.name}", "#{total_spending} из #{limit}"]
    end)
  end

  defp render_folder_with_multiple_category(current_user, folder, categories) do
    acc = []
    acc = acc ++ [["#{folder.name}", ""]]

    acc ++
      Enum.map(categories, fn category ->
        total_spending =
          Transactions.get_category_monthly_spendings(current_user.id, category.id, [])
          |> round()

        limit = limit_value(category)

        if List.last(categories) == category do
          [" └#{category.name}", "#{total_spending} из #{limit}"]
        else
          [" ├#{category.name}", "#{total_spending} из #{limit}"]
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
