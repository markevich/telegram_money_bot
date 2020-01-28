defmodule MarkevichMoney.Steps.Transaction.CalculateAmountSign do
  @regex ~r/(?<income>На счёт:)|(?<outcome>Со счёта)/

  def call(%{input_message: input_message, parsed_attributes: %{amount: amount}} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :amount, amount * sign(input_message))
    end)
  end

  defp sign(input_message) do
    result = Regex.named_captures(@regex, input_message)

    cond do
      String.trim(result["income"]) != "" -> 1
      String.trim(result["outcome"]) != "" -> -1
    end
  end
end
