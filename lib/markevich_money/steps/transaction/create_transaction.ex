defmodule MarkevichMoney.Steps.Transaction.CreateTransaction do
  alias MarkevichMoney.Transactions

  def call(payload) do
    payload
    |> Map.put(:transaction, create_transaction())
  end

  defp create_transaction do
    {:ok, transaction} = Transactions.create_transaction()

    transaction
  end
end
