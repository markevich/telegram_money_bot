defmodule TelegramMoneyBot.Steps.Transaction.CreateTransaction do
  alias TelegramMoneyBot.Repo
  alias TelegramMoneyBot.Transactions
  alias TelegramMoneyBot.Transactions.Transaction

  def call(%{parsed_attributes: parsed_attributes} = payload) do
    payload
    |> Map.put(:transaction, create_transaction(parsed_attributes))
  end

  defp create_transaction(attrs) do
    transaction =
      %Transaction{}
      |> Transaction.create_changeset(attrs)
      |> Repo.insert!()

    Transactions.get_transaction!(transaction.id)
  end
end
