defmodule MarkevichMoney.Gamification.Events.Broadcaster do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit, as: LimitTracker
  alias MarkevichMoney.LoggerWithSentry

  use Oban.Worker, queue: :events, max_attempts: 2

  @impl Oban.Worker
  def perform(%Job{args: %{"event" => event, "transaction_id" => _t_id} = payload})
      when event in [@transaction_created_event, @transaction_updated_event] do
    payload
    |> LimitTracker.new()
    |> Oban.insert()

    :ok
  end

  def perform(%Job{args: args}) do
    LoggerWithSentry.log_message(
      "'#{__MODULE__}' worker received unknown arguments.",
      %{args: args}
    )

    :ok
  end
end
