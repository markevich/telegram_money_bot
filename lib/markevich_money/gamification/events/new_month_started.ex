defmodule MarkevichMoney.Gamification.Events.NewMonthStarted do
  use MarkevichMoney.Constants
  use MarkevichMoney.LoggerWithSentry

  use Oban.Worker, queue: :events, max_attempts: 1

  alias MarkevichMoney.Pipelines.Reports.MonthlyReport.Worker, as: MonthlyReportWorker
  alias MarkevichMoney.Users

  @impl Oban.Worker
  def perform(_job) do
    Users.all_users()
    |> Enum.each(fn user ->
      %{
        user_id: user.id
      }
      |> MonthlyReportWorker.new()
      |> Oban.insert()
    end)

    :ok
  end
end
