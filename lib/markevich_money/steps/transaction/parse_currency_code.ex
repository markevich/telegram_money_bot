defmodule MarkevichMoney.Steps.Transaction.ParseCurrencyCode do
  @regex ~r/Сумма:.*\(?\d+\.?\d*\s?(?<currency_code>\w+)\)?/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :currency_code, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    result["currency_code"]
  end
end
