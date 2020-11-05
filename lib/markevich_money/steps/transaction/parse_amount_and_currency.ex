defmodule MarkevichMoney.Steps.Transaction.ParseAmountAndCurrency do
  @regex ~r/Сумма:((?<amount>\d+\.?\d*)\s(?<currency>\w{3}))(\s\((?<external_amount>\d+\.?\d*)\s(?<external_currency>\w{3})\))?/

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
      {origin_card_amount, _} = Float.parse(amount)

      %{amount: origin_card_amount, currency_code: currency}
    else
      # If we have two currencies "11 USD (10 EUR)" so real card amount and currency is external
      {origin_card_amount, _} = Float.parse(external_amount)
      {external_card_amount, _} = Float.parse(amount)

      %{
        amount: origin_card_amount,
        currency_code: external_currency,
        external_amount: external_card_amount,
        external_currency: currency
      }
    end
  end
end
