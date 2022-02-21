defmodule MarkevichMoney.Steps.Transaction.ParseCustomTransactionMessage do
  use MarkevichMoney.Constants

  @regex1 ~r/#{@add_message}\s+(?<amount>\d+[\.,]?\d*)\s+(?<to>\D+)/u
  @regex2 ~r/#{@add_message}\s+(?<to>\D+)\s+(?<amount>\d+[\.,]?\d*)/u

  def call(%{message: input_message, current_user: current_user} = payload) do
    payload
    |> Map.put(:parsed_attributes, extract_attrs(input_message, current_user))
  end

  def valid_message?(input_message) do
    parsed = parse_message(input_message)

    !!parsed
  end

  defp extract_attrs(input_message, current_user) do
    parsed = parse_message(input_message)
    amount = String.replace(parsed["amount"], ",", ".")

    {float_amount, _} = Float.parse(amount)

    # TODO: add correct currency code for show
    %{
      amount: -float_amount,
      to: to_string(parsed["to"]),
      account: @manual_account,
      currency_code: "BYN",
      user_id: current_user.id,
      balance: 0,
      status: @transaction_status_normal,
      issued_at: DateTime.utc_now(),
      lookup_hash: Ecto.UUID.generate()
    }
  end

  defp parse_message(input_message) do
    [@regex1, @regex2]
    |> Enum.find_value(fn regex ->
      parsed = Regex.named_captures(regex, input_message)

      validate_parsed(parsed) && parsed
    end)
  end

  defp validate_parsed(parsed) do
    !!(parsed && parsed["amount"] && parsed["to"])
  end
end
