defmodule MarkevichMoney.Pipelines.Reports.MonthlyReport.WorkerTest do
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo

  alias MarkevichMoney.Pipelines.Reports.MonthlyReport
  alias MarkevichMoney.Pipelines.Reports.MonthlyReport.Worker

  defmock MarkevichMoney.Pipelines.Reports.MonthlyReport do
    def call(_user_id) do
      {:ok}
    end
  end

  describe "perform" do
    mocked_test "calls the reporter" do
      user_id = 1

      :ok =
        Worker
        |> perform_job(%{"user_id" => user_id})

      assert_called(MonthlyReport.call(user_id))
    end
  end
end
