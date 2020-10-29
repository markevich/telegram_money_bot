defmodule MarkevichMoney.Steps.Transaction.CalculateAmountSign do
  @income_regex ~r/возврат|На счёт:/i

  def call(%{input_message: input_message, parsed_attributes: %{amount: amount}} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :amount, amount * sign(input_message))
    end)
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
