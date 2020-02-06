defmodule MarkevichMoney.Steps.Transaction.ParseDateTime do
  @regex ~r/\n(?<day>\d+)\.(?<month>\d+)\.(?<year>\d{4})\s?(?<hour>\d+)?:?(?<minute>\d+)?:?(?<second>\d+)?/

  def call(%{input_message: input_message} = payload) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :datetime, extract_datetime(input_message))
    end)
  end

  defp extract_datetime(input_message) do
    result = Regex.named_captures(@regex, input_message)

    {:ok, datetime} =
      if result["hour"] != "" do
        NaiveDateTime.new(
          String.to_integer(result["year"]),
          String.to_integer(result["month"]),
          String.to_integer(result["day"]),
          String.to_integer(result["hour"]),
          String.to_integer(result["minute"]),
          String.to_integer(result["second"])
        )
      else
        NaiveDateTime.new(
          String.to_integer(result["year"]),
          String.to_integer(result["month"]),
          String.to_integer(result["day"]),
          0,
          0,
          0
        )
      end

    datetime
  end
end
