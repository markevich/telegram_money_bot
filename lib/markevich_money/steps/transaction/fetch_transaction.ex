defmodule MarkevichMoney.Steps.Transaction.FetchTransaction do
  alias MarkevichMoney.Transactions

  def call(%{transaction_id: transaction_id} = payload) do
    payload
    |> Map.put(:transaction, Transactions.get_transaction!(transaction_id))
  end
end
