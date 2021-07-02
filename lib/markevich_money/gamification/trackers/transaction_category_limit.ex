defmodule MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit do
  use Oban.Worker, queue: :trackers, max_attempts: 1
  use MarkevichMoney.LoggerWithSentry

  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.ProgressBar
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Users

  @impl Oban.Worker
  def perform(%Job{args: %{"transaction_id" => _t_id} = payload}) do
    updated_payload = call(payload)

    {:ok, updated_payload}
  end

  def perform(%Job{args: args}) do
    log_error_message(
      "'#{__MODULE__}' worker received unknown arguments.",
      %{args: args}
    )

    :ok
  end

  def call(%{"transaction_id" => transaction_id} = payload) do
    with transaction <- Transactions.get_transaction!(transaction_id),
         user <- Users.get_user!(transaction.user_id),
         {:ok, category_id} when category_id != nil <-
           Map.fetch(transaction, :transaction_category_id),
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

      if total_with_current_percentage > 100 || new_milestone do
        progress_bar =
          ProgressBar.call(total_with_current, category_limit, transaction.currency_code)

        output_message = """
        *Внимание! В категории \"#{transaction.transaction_category.name}\" потрачено #{trunc(total_with_current_percentage)}% месячного бюджета.*
        #{progress_bar}
        """

        payload
        |> Map.put(:current_user, user)
        |> Map.put(:output_message, output_message)
        |> SendMessage.call()
      else
        payload
      end
    else
      _ -> payload
    end
  end
end
