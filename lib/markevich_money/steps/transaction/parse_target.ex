defmodule MarkevichMoney.Steps.Transaction.ParseTarget do
  @regex ~r/На время.*\n(?<target>.*)\n/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :target, extract_account(input_message))
    end)
  end

  defp extract_account(input_message) do
    result = Regex.named_captures(@regex, input_message)

    String.trim(result["target"])
  end
end
