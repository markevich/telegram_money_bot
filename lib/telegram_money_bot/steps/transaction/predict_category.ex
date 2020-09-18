defmodule TelegramMoneyBot.Steps.Transaction.PredictCategory do
  alias TelegramMoneyBot.Transactions

  def call(%{parsed_attributes: %{to: to}, current_user: %{id: user_id}} = payload)
      when is_binary(to) do
    payload
    |> Map.update!(:parsed_attributes, fn parsed_data ->
      Map.put(parsed_data, :transaction_category_id, predict_category_id(to, user_id))
    end)
  end

  def predict_category_id(to, user_id) do
    Transactions.predict_category_id(to, user_id)
  end
end
