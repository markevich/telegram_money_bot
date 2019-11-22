defmodule MarkevichMoney.Steps.Transaction.CreateTransaction do
  alias MarkevichMoney.Transactions

  def call(payload) do
    payload
    |> Map.put(:transaction_id, create_transaction().id)
  end

  defp create_transaction do
    {:ok, transaction} = Transactions.create_transaction()

    Transactions.get_transaction!(transaction.id)
  end
end
