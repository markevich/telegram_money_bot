defmodule TelegramMoneyBot.ProgressBar do
  @filled_symbol "⣿"
  @empty_symbol "⣀"
  @max_length 25

  def call(current, limit, currency) do
    percentage = trunc(current / limit * 100)

    progress_bar = render_progress_bar(percentage)
    stats = render_stats(percentage, current, limit, currency)

    """
    ```
    #{progress_bar}\n#{stats}
    ```
    """
  end

  defp render_progress_bar(percentage) when percentage >= 100.0 do
    bar = String.duplicate(@filled_symbol, @max_length - 2)
    "|#{bar}|"
  end

  defp render_progress_bar(percentage) do
    # FYI: 2 is number of the "|" symbol
    number_of_filled = trunc(percentage / 100 * @max_length - 2)
    filled = String.duplicate(@filled_symbol, number_of_filled)
    empty = String.duplicate(@empty_symbol, @max_length - 2 - number_of_filled)
    "|#{filled}#{empty}|"
  end

  defp render_stats(percentage, current, limit, currency) do
    current = trunc(current)
    currency = String.upcase(currency)

    "#{percentage}% (#{current}/#{limit}) #{currency}"
    |> center_string()
  end

  defp center_string(input) do
    diff_length = @max_length - String.length(input)
    padding = max(div(diff_length, 2), 0)

    if padding > 0 do
      String.pad_leading(input, @max_length - padding)
    else
      input
    end
  end
end
