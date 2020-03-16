defmodule MarkevichMoney.Steps.Transaction.ParseCustomTransactionMessage do
  @regex ~r/\/add\s(?<amount>\d+\.?\d*)\s(?<to>\w+)/u

  def call(%{message: input_message, current_user: current_user} = payload) do
    payload
    |> Map.put(:parsed_attributes, extract_attrs(input_message, current_user))
  end

  defp extract_attrs(input_message, current_user) do
    result = Regex.named_captures(@regex, input_message)
    {float_amount, _} = Float.parse(result["amount"])

    %{
      amount: -float_amount,
      to: to_string(result["to"]),
      account: "manual",
      currency_code: "byn",
      user_id: current_user.id,
      balance: 0,
      datetime: DateTime.utc_now(),
      lookup_hash: Ecto.UUID.generate()
    }
  end
end
