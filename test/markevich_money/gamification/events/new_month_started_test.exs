defmodule MarkevichMoney.Gamification.Events.NewMonthStartedTest do
  use MarkevichMoney.DataCase, async: true
  use Oban.Testing, repo: MarkevichMoney.Repo

  alias MarkevichMoney.Gamification.Events.NewMonthStarted
  alias MarkevichMoney.Pipelines.Reports.MonthlyReport.Worker, as: ReportWorker

  describe "perform" do
    test "schedule report job for each user" do
      user1 = insert(:user)
      user2 = insert(:user)

      :ok =
        NewMonthStarted
        |> perform_job(%{})

      assert_enqueued(
        worker: ReportWorker,
        args: %{user_id: user1.id}
      )

      assert_enqueued(
        worker: ReportWorker,
        args: %{user_id: user2.id}
      )
    end
  end
end
