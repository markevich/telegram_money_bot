defmodule MarkevichMoney.Steps.Transaction.DeleteTransaction do
  alias MarkevichMoney.Transactions

  def call(%{transaction_id: transaction_id} = payload) do
    Transactions.delete_transaction(transaction_id)

    payload
  end
end
