defmodule MarkevichMoney.Priorbank.FetcherWorker do
  use Oban.Worker, queue: :priorbank_fetcher, max_attempts: 2

  alias MarkevichMoney.Priorbank

  def perform(%Job{args: %{"connection_id" => connection_id}}) do
    connection_id
    |> Priorbank.get_connection!()
    |> Priorbank.fetch_latest_transactions()

    :ok
  end
end
