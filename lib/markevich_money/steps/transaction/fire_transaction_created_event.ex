defmodule MarkevichMoney.Steps.Transaction.FireTransactionCreatedEvent do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Gamification.Events.Broadcaster

  def call(%{transaction: transaction, current_user: current_user} = payload) do
    %{event: @transaction_created_event, transaction_id: transaction.id, user_id: current_user.id}
    |> Broadcaster.new()
    |> Oban.insert()

    payload
  end
end
