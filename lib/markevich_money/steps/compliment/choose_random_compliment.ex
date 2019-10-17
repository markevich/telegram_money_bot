defmodule MarkevichMoney.Steps.Compliment.ChooseRandomCompliment do
  def call(%{compliments: compliments} = payload) do
    payload
    |> Map.put(:output_message, Enum.random(compliments))
  end
end
