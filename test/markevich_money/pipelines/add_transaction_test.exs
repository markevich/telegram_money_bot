defmodule MarkevichMoney.Pipelines.AddTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use Oban.Testing, repo: MarkevichMoney.Repo
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  describe "/add message" do
    setup do
      user = insert(:user)
      to = "Something great"
      amount = 50.23
      category = insert(:transaction_category)

      insert(:transaction_category_prediction,
        prediction: to,
        transaction_category_id: category.id
      )

      %{user: user, category: category, to: to, amount: amount}
    end

    mocked_test "insert and renders transaction, fire event", context do
      #  FYI: /add 50.23 Something great
      reply_payload =
        Pipelines.call(%MessageData{
          message: "/add #{context.amount} #{context.to}",
          chat_id: context.user.telegram_chat_id
        })

      transaction = reply_payload[:transaction]

      assert(%Transaction{} = transaction)
      assert(transaction.user_id == context.user.id)
      assert(transaction.amount == Decimal.from_float(-context.amount))
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.to == context.to)
      assert(transaction.balance == Decimal.new(0))

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: "transaction_created",
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end
end
