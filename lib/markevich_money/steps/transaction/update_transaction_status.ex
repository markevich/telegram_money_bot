defmodule MarkevichMoney.Steps.Transaction.UpdateTransactionStatus do
  alias MarkevichMoney.Transactions

  def call(%{transaction_id: transaction_id} = payload, new_status) do
    Transactions.update_status(transaction_id, new_status)

    payload
  end
end
