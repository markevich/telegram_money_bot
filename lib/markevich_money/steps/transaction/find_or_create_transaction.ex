defmodule MarkevichMoney.Steps.Transaction.FindOrCreateTransaction do
  alias MarkevichMoney.Transactions

  def call(payload) do
    transaction = find_or_create_transaction(payload)

    Map.put(payload, :transaction_id, transaction.id)
  end

  defp find_or_create_transaction(%{
         parsed_attributes: %{account: account, type: type, amount: amount, datetime: datetime}
       }) do
    {:ok, transaction} = Transactions.upsert_transaction(account, type, amount, datetime)

    Transactions.get_transaction!(transaction.id)
  end
end
