defmodule MarkevichMoney.Steps.Transaction.FireTransactionUpdatedEvent do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Gamification.Events.Broadcaster

  def call(%{transaction: transaction, current_user: current_user} = payload) do
    %{event: @transaction_updated_event, transaction_id: transaction.id, user_id: current_user.id}
    |> Broadcaster.new()
    |> Oban.insert()

    payload
  end
end
