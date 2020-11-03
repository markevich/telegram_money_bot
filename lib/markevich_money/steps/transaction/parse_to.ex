defmodule MarkevichMoney.Steps.Transaction.ParseTo do
  @regex ~r/На время.*\n(?<to>.*)\n?/
  @fallback_regex ~r/Со счёта.*\n(?<to>.*)\n?/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :to, extract_to(input_message))
    end)
  end

  defp extract_to(input_message) do
    parse_target(input_message)
    |> String.trim()
  end

  defp parse_target(input_message) do
    result = Regex.named_captures(@regex, input_message)

    if result["to"] do
      result["to"]
    else
      Regex.named_captures(@fallback_regex, input_message)["to"]
    end
  end
end
