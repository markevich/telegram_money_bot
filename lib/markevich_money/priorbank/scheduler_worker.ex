defmodule MarkevichMoney.Priorbank.SchedulerWorker do
  use Oban.Worker, queue: :priorbank_scheduler, max_attempts: 1

  alias MarkevichMoney.Priorbank.FetcherWorker
  alias MarkevichMoney.Priorbank.PriorbankConnection
  alias MarkevichMoney.Repo

  def perform(_) do
    PriorbankConnection
    |> Repo.all()
    |> Enum.each(fn connection ->
      schedule_priorbank_fetching(connection.id)
    end)

    :ok
  end

  defp schedule_priorbank_fetching(connection_id) do
    %{connection_id: connection_id}
    |> FetcherWorker.new()
    |> Oban.insert()
  end
end
