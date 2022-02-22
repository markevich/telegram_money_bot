defmodule MarkevichMoney.Pipelines.UpdateTransactionStatus do
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines.RerenderTransaction
  alias MarkevichMoney.Steps.Transaction.{UpdateTransactionStatus}

  def call(%CallbackData{callback_data: %{"action" => action}} = callback_data) do
    new_status =
      case action do
        @transaction_set_ignored_status_callback -> @transaction_status_ignored
        @transaction_set_normal_status_callback -> @transaction_status_normal
      end

    callback_data
    |> update_status(new_status)
  end

  defp update_status(callback_data, new_status) do
    callback_data
    |> fetch_transaction_id()
    |> UpdateTransactionStatus.call(new_status)
    |> RerenderTransaction.call()
  end

  defp fetch_transaction_id(%{callback_data: %{"id" => transaction_id}} = payload) do
    payload
    |> Map.put(:transaction_id, transaction_id)
  end
end
