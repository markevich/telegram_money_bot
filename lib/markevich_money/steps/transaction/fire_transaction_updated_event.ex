defmodule MarkevichMoney.Steps.Transaction.FireTransactionUpdatedEvent do
  alias MarkevichMoney.Gamification.Events.Broadcaster

  def call(%{transaction: transaction, current_user: current_user} = payload) do
    %{event: :transaction_updated, transaction_id: transaction.id, user_id: current_user.id}
    |> Broadcaster.new()
    |> Oban.insert()

    payload
  end
end
