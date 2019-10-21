defmodule MarkevichMoney.Steps.Transaction.ParseAccount do
  @regex ~r/Со счёта:\s(?<account>.*)\n/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :account, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    result["account"]
  end
end
