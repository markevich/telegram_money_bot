defmodule MarkevichMoney.Steps.Transaction.ParseAmount do
  @regex ~r/Сумма:((?<amount>\d+\.\d+)\s\w{3})(\s\((?<amount_converted>\d+\.\d+)\s\w{3}\))?/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :amount, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    if String.trim(result["amount_converted"]) != "" do
      String.trim(result["amount_converted"])
    else
      String.trim(result["amount"])
    end
  end
end
