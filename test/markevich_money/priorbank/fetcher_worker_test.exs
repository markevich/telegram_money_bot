defmodule MarkevichMoney.Priorbank.FetcherWorkerTest do
  use MarkevichMoney.DataCase, async: true
  use Oban.Testing, repo: MarkevichMoney.Repo
  use MecksUnit.Case

  alias MarkevichMoney.Priorbank.FetcherWorker

  describe "perform" do
    setup do
      %{
        connection: insert(:priorbank_connection)
      }
    end

    defmock MarkevichMoney.Priorbank do
      def fetch_latest_transactions(_) do
      end
    end

    mocked_test "Calls the priorbank transactions fetcher", context do
      :ok =
        FetcherWorker
        |> perform_job(%{"connection_id" => context.connection.id})

      assert_called(MarkevichMoney.Priorbank.fetch_latest_transactions(context.connection))
    end
  end
end
