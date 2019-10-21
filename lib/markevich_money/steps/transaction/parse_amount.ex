defmodule MarkevichMoney.Steps.Transaction.ParseAmount do
  @regex ~r/Сумма:\s*(?<amount>\d*\.\d*)\s/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :amount, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    result["amount"]
  end
end
