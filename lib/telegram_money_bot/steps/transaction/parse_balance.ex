defmodule TelegramMoneyBot.Steps.Transaction.ParseBalance do
  @regex ~r/Остаток:\s*(?<balance>\d*\.\d*)\s/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :balance, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    result["balance"]
  end
end
