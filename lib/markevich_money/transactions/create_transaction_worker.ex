defmodule MarkevichMoney.Transactions.CreateTransactionWorker do
  use Oban.Worker, queue: :transactions, max_attempts: 1, unique: [period: :infinity]
  use MarkevichMoney.LoggerWithSentry

  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Steps.Transaction.FireTransactionCreatedEvent
  alias MarkevichMoney.Steps.Transaction.RenderTransaction
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Users

  @impl Oban.Worker
  def perform(%Job{args: %{"transaction_attributes" => _attributes} = payload}) do
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

  # TODO: Let's use the `transaction_attributes` key across all of the `Steps`.
  #   Current key name: `parsed_attributes`
  # TODO: Use Oban worklflow to split that workers into relays
  defp call(%{"transaction_attributes" => attributes} = payload) do
    user = Users.get_user!(attributes["user_id"])

    upsert_result =
      Transactions.upsert_transaction(
        user.id,
        attributes["account"],
        attributes["amount"],
        attributes["issued_at"],
        attributes["temporary"]
      )

    case upsert_result do
      {:exists, transaction} ->
        payload
        |> Map.put(:transaction, transaction)

      {:new, transaction} ->
        # TODO: Call Steps.PredictCategory once arguments keys will establish
        attributes =
          Map.put(
            attributes,
            "transaction_category_id",
            Transactions.predict_category_id(attributes["to"], user.id)
          )

        {:ok, transaction} = Transactions.update_transaction(transaction, attributes)

        payload
        |> Map.put(:transaction, transaction)
        |> Map.put(:current_user, user)
        |> RenderTransaction.call()
        |> SendMessage.call()
        |> FireTransactionCreatedEvent.call()
    end
  end
end
