defmodule MarkevichMoney.Steps.Transaction.DetermineTransactionStatus do
  @requires_confirmation_regex ~r/BLR\/ONLINE SERVICE\/TRANSFERS\sAK\sAM/i

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :status, guess_status(input_message))
    end)
  end

  defp guess_status(input_message) do
    if Regex.match?(@requires_confirmation_regex, input_message) do
      :requires_confirmation
    else
      :normal
    end
  end
end
