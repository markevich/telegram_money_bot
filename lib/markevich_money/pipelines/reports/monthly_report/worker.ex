defmodule MarkevichMoney.Pipelines.Reports.MonthlyReport.Worker do
  use MarkevichMoney.Constants
  use MarkevichMoney.LoggerWithSentry
  use Oban.Worker, queue: :reports, max_attempts: 1

  alias MarkevichMoney.Pipelines.Reports.MonthlyReport

  @impl Oban.Worker
  def perform(%Job{args: %{"user_id" => user_id}}) do
    MonthlyReport.call(user_id)

    :ok
  end
end
