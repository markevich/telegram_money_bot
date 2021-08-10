defmodule MarkevichMoney.Gamification.Events.ReportSender do
  use MarkevichMoney.Constants
  use MarkevichMoney.LoggerWithSentry
  use Oban.Worker, queue: :reports, max_attempts: 1

  alias MarkevichMoney.Pipelines.Reports.ComparedExpenses

  @impl Oban.Worker
  def perform(%Job{args: %{"user_id" => user_id}}) do
    ComparedExpenses.call(user_id)

    :ok
  end
end
