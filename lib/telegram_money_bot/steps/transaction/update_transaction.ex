defmodule TelegramMoneyBot.Steps.Transaction.UpdateTransaction do
  alias TelegramMoneyBot.Transactions
  alias TelegramMoneyBot.Transactions.Transaction

  def call(%{parsed_attributes: parsed_attributes, transaction_id: transaction_id} = payload) do
    payload
    |> Map.put(:transaction, update_transaction(transaction_id, parsed_attributes))
  end

  defp update_transaction(transaction_id, attrs) do
    {:ok, transaction} =
      %Transaction{id: transaction_id}
      |> Transactions.update_transaction(attrs)

    Transactions.get_transaction!(transaction.id)
  end
end
