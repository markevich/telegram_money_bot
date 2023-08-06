defmodule MarkevichMoney.Steps.Transaction.ParseAmountAndCurrency do
  # credo:disable-for-next-line
  @regex ~r/Сумма:((?<amount>[\d\s]+\.?\d*)\s(?<currency>\w{3}))(\s\((?<external_amount>[\d\s+]+\.?\d*)\s(?<external_currency>\w{3})\))?/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.merge(parsed_data, match_attributes(input_message))
    end)
  end

  defp match_attributes(input_message) do
    Regex.named_captures(@regex, input_message)
    |> parse_attributes
  end

  defp parse_attributes(%{
         "amount" => amount,
         "currency" => currency,
         "external_amount" => external_amount,
         "external_currency" => external_currency
       }) do
    if external_amount == "" do
      {origin_card_amount, _} =
        Regex.replace(~r/\s/u, amount, "")
        |> Float.parse()

      %{amount: origin_card_amount, currency_code: currency}
    else
      # If we have two currencies in transaction, ie "11 USD (25 BYN)",
      # then first number is `external_amount`, second is `amount`

      {origin_card_amount, _} =
        Regex.replace(~r/\s/u, external_amount, "")
        |> Float.parse()

      {external_card_amount, _} =
        Regex.replace(~r/\s/u, amount, "")
        |> Float.parse()

      %{
        amount: origin_card_amount,
        currency_code: external_currency,
        external_amount: external_card_amount,
        external_currency: currency
      }
    end
  end
end
