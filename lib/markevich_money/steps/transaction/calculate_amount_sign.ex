defmodule MarkevichMoney.Steps.Transaction.CalculateAmountSign do
  @income_regex ~r/возврат|На счёт:|Внесение/i

  def call(%{input_message: input_message, parsed_attributes: %{amount: _amount}} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      update_parsed_data_sign(input_message, parsed_data)
    end)
  end

  defp update_parsed_data_sign(input_message, parsed_data) do
    calculated_sign = sign(input_message)

    parsed = Map.put(parsed_data, :amount, parsed_data[:amount] * calculated_sign)

    if Map.has_key?(parsed_data, :external_amount) do
      parsed
      |> Map.put(:external_amount, parsed_data[:external_amount] * calculated_sign)
    else
      parsed
    end
  end

  defp sign(input_message) do
    income = Regex.match?(@income_regex, input_message)

    if income do
      1
    else
      -1
    end
  end
end
