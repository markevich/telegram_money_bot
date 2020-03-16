defmodule MarkevichMoney.Steps.Transaction.PredictCategory do
  alias MarkevichMoney.Transactions

  def call(%{parsed_attributes: %{to: to}} = payload) when is_binary(to) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :transaction_category_id, predict_category_id(to))
    end)
  end

  def predict_category_id(to) do
    case Transactions.predict_category_id(to) do
      category_id when is_integer(category_id) ->
        category_id

      nil ->
        nil
    end
  end
end
