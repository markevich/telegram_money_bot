defmodule MarkevichMoney.Priorbank do
  alias MarkevichMoney.Priorbank.Integration
  alias MarkevichMoney.Priorbank.PriorbankConnection
  alias MarkevichMoney.Repo
  alias MarkevichMoney.Transactions.CreateTransactionWorker

  def get_connection!(id) do
    PriorbankConnection
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  def fetch_latest_transactions(connection) do
    connection
    |> Integration.fetch_priorbank_transactions()
    |> Integration.convert_to_readable_transaction_attributes()
    |> schedule_transactions_creation(connection.user)

    Integration.update_last_fetched_at!(connection)
  end

  defp schedule_transactions_creation(readable_transactions_attributes, user) do
    Enum.map(readable_transactions_attributes, fn attributes ->
      attributes = Map.put(attributes, :user_id, user.id)

      %{transaction_attributes: attributes, source: :priorbank}
      |> CreateTransactionWorker.new()
      |> Oban.insert()
    end)
  end
end
