defmodule MarkevichMoney.Steps.Transaction.PredictCategory do
  alias MarkevichMoney.Transactions

  def call(%{parsed_attributes: %{target: target}} = payload) when is_binary(target) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :transaction_category_id, predict_category_id(target))
    end)
  end

  def predict_category_id(target) do
    case Transactions.predict_category_id(target) do
      category_id when is_integer(category_id) ->
        category_id

      nil ->
        nil
    end
  end
end
