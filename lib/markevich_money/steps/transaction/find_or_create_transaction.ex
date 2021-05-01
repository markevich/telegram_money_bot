defmodule MarkevichMoney.Steps.Transaction.FindOrCreateTransaction do
  alias MarkevichMoney.Transactions

  def call(payload) do
    transaction = find_or_create_transaction(payload)

    Map.put(payload, :transaction_id, transaction.id)
  end

  defp find_or_create_transaction(%{
         parsed_attributes: %{account: account, amount: amount, issued_at: issued_at},
         current_user: current_user
       }) do
    case Transactions.upsert_transaction(current_user.id, account, amount, issued_at) do
      # TODO: That code means that we probably have an incorrect processing of transactions from alfabank.
      #   New and existing transactions will behave like the `new` one,
      #   i.e sending messages to the users and firing `created` events.
      {status, transaction} when status in [:exists, :new] ->
        Transactions.get_transaction!(transaction.id)
    end
  end
end
