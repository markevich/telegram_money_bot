defmodule MarkevichMoney.Steps.Transaction.DetermineTransactionStatus do
  @requires_confirmation_regex ~r/BLR\/ONLINE SERVICE\/TRANSFERS\sAK\sAM/i

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :status, guess_status(parsed_data, input_message))
    end)
  end

  defp guess_status(parsed_data, input_message) do
    with true <- match_confirmation_regex?(input_message),
         amount when amount < 0 <- get_amount(parsed_data) do
      :requires_confirmation
    else
      _ -> :normal
    end
  end

  defp match_confirmation_regex?(input_message) do
    Regex.match?(@requires_confirmation_regex, input_message)
  end

  defp get_amount(parsed_data) do
    %{parsed_attributes: %{amount: amount}} = parsed_data

    amount
  end
end
