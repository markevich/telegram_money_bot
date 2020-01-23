defmodule MarkevichMoney.Steps.Transaction.ParseCustomTransactionMessage do
  @regex ~r/\/add\s(?<amount>\d+)\s(?<target>\w+)/u

  def call(%{message: input_message} = payload) do
    payload
    |> Map.put(:parsed_attributes, extract_attrs(input_message))
  end

  defp extract_attrs(input_message) do
    result = Regex.named_captures(@regex, input_message)

    %{
      amount: Decimal.new(result["amount"]),
      target: to_string(result["target"]),
      account: "manual",
      currency_code: "byn",
      balance: 0,
      type: "outcome",
      datetime: DateTime.utc_now(),
      lookup_hash: Ecto.UUID.generate()
    }
  end
end
