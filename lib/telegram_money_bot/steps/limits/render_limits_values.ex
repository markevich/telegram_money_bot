defmodule TelegramMoneyBot.Steps.Limits.RenderLimitsValues do
  use TelegramMoneyBot.Constants
  alias TelegramMoneyBot.Steps.Limits.RenderLimitsStats

  def call(%{limits: limits, current_user: _current_user} = payload) do
    limits_values = render_limits_table(limits)
    limits_stats = RenderLimitsStats.call(payload)[:output_message]

    message = """
    ```

    #{limits_values}
    ```
    #{limits_stats}
    Для установки лимита используйте:

    *#{@set_limit_message} id value*
    """

    payload
    |> Map.put(:output_message, message)
  end

  defp render_limits_table(limits) do
    limits
    |> Enum.map(fn category ->
      [category.id, category.name, limit_value(category)]
    end)
    |> TableRex.Table.new(["id", "Категория", "Лимит"], "Лимиты по категориям")
    |> TableRex.Table.put_column_meta(:all, align: :left, padding: 1)
    |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)
  end

  defp limit_value(category) do
    case category.transaction_category_limit do
      nil -> "♾️"
      # credo:disable-for-next-line
      category_limit -> if category_limit.limit == 0, do: "♾️", else: category_limit.limit
    end
  end
end
