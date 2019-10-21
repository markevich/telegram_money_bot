defmodule MarkevichMoney.Steps.Transaction.UpdateTransaction do
  alias MarkevichMoney.Transactions

  def call(%{parsed_attributes: parsed_attributes, transaction: transaction} = payload) do
    payload
    |> Map.put(:transaction, update_transaction(transaction, parsed_attributes))
  end

  defp update_transaction(transaction, attrs) do
    {:ok, transaction} = Transactions.update_transaction(transaction, attrs)

    transaction
  end
end
