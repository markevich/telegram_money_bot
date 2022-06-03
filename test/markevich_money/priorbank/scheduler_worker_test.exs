defmodule MarkevichMoney.Priorbank.SchedulerWorkerTest do
  use MarkevichMoney.DataCase, async: true
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo

  alias MarkevichMoney.Priorbank.FetcherWorker
  alias MarkevichMoney.Priorbank.SchedulerWorker

  describe "perform" do
    setup do
      %{
        connection_ids:
          [
            insert(:priorbank_connection),
            insert(:priorbank_connection)
          ]
          |> Enum.map(fn c -> c.id end)
      }
    end

    test "schedule fetcher for each existing priorbank connection", context do
      :ok =
        SchedulerWorker
        |> perform_job(%{})

      Enum.each(context.connection_ids, fn connection_id ->
        assert_enqueued(
          worker: FetcherWorker,
          args: %{connection_id: connection_id}
        )
      end)
    end
  end
end
