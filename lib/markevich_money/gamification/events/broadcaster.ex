defmodule MarkevichMoney.Gamification.Events.Broadcaster do
  use Oban.Worker, queue: :events, max_attempts: 2
  require Logger

  alias MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit, as: LimitTracker

  @impl Oban.Worker
  def perform(%{"event" => event, "transaction_id" => _t_id} = payload, _job)
      when event in ["transaction_created", "transaction_updated"] do
    payload
    |> LimitTracker.new()
    |> Oban.insert()

    :ok
  end

  def perform(args, job) do
    Sentry.capture_message("#{__MODULE__} worker received unknown arguments",
      extra: %{args: args, job: job}
    )

    Logger.error("""
    #{__MODULE__} worker received unknown arguments.
    args: #{inspect(args)}
    job: #{inspect(job)}
    """)

    :ok
  end
end
