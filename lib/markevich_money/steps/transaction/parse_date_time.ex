defmodule MarkevichMoney.Steps.Transaction.ParseDateTime do
  @regex ~r/\n(?<day>\d+)\.(?<month>\d+)\.(?<year>\d{4})\s(?<time>[\d:]+)/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :datetime, extract_datetime(input_message))
    end)
  end

  defp extract_datetime(input_message) do
    result = Regex.named_captures(@regex, input_message)

    ~s(#{result["year"]}-#{result["month"]}-#{result["day"]} #{result["time"]})
  end
end
