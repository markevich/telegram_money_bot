defmodule MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit do
  require Logger
  use Oban.Worker, queue: :trackers, max_attempts: 1

  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Users

  @impl Oban.Worker
  def perform(%{"transaction_id" => _t_id} = payload, _job) do
    updated_payload = call(payload)

    {:ok, updated_payload}
  end

  def perform(args, job) do
    Sentry.capture_message("#{__MODULE__} worker received unknown arguments",
      extra: %{args: args, job: job}
    )

    Logger.error("""
    "#{__MODULE__} worker received unknown arguments".
    args: #{inspect(args)}
    job: #{inspect(job)}
    """)

    :ok
  end

  def call(%{"transaction_id" => transaction_id} = payload) do
    with transaction <- Transactions.get_transaction!(transaction_id),
         user <- Users.get_user!(transaction.user_id),
         {:ok, category_id} <- Map.fetch(transaction, :transaction_category_id),
         category_limit when category_limit > 0 <-
           Gamifications.get_category_limit_value(transaction.user_id, category_id) do
      #
      total_without_current =
        Transactions.get_category_monthly_spendings(transaction.user_id, category_id, [
          transaction.id
        ])

      total_with_current =
        Transactions.get_category_monthly_spendings(transaction.user_id, category_id, [])

      total_without_current_percentage =
        Float.round(total_without_current / category_limit * 100, 2)

      total_with_current_percentage = Float.round(total_with_current / category_limit * 100, 2)

      thresholds = [50, 70, 90, 100]

      new_milestone =
        thresholds
        |> Enum.reverse()
        |> Enum.find(fn el ->
          total_without_current_percentage < el and el < total_with_current_percentage
        end)

      if total_with_current > 100 || new_milestone do
        payload
        |> Map.put(:current_user, user)
        |> Map.put(:output_message, """
        *Внимание! В категории "#{transaction.transaction_category.name}" потрачено #{
          total_with_current_percentage
        }% (#{total_with_current} #{String.upcase(transaction.currency_code)}) из установленного лимита в #{
          category_limit
        } #{String.upcase(transaction.currency_code)}*
        """)
        |> SendMessage.call()
      else
        payload
      end
    else
      _ -> payload
    end
  end
end
