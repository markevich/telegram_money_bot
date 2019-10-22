defmodule MarkevichMoney.Steps.Transaction.ParseType do
  @regex ~r/(?<income>На счёт:)|(?<outcome>Со счёта)/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :type, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    cond do
      String.trim(result["income"]) != "" -> "income"
      String.trim(result["outcome"]) != "" -> "outcome"
      true -> "unknown"
    end
  end
end
