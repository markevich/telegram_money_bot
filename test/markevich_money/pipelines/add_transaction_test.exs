defmodule MarkevichMoney.Pipelines.AddTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use Oban.Testing, repo: MarkevichMoney.Repo
  use MarkevichMoney.Constants
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  describe "#{@add_message} message" do
    setup do
      user = insert(:user)
      to = "Something great"
      category = insert(:transaction_category)

      # prediction
      insert(:transaction,
        user: user,
        to: to,
        amount: 10,
        transaction_category_id: category.id
      )

      %{user: user, category: category, to: to}
    end

    mocked_test "insert and renders transaction, fire event", context do
      #  FYI: /add 50.23 Something great
      amount = 50.23

      reply_payload =
        Pipelines.call(%MessageData{
          message: "#{@add_message} #{amount} #{context.to}",
          chat_id: context.user.telegram_chat_id
        })

      transaction = reply_payload[:transaction]

      assert(%Transaction{} = transaction)
      assert(transaction.user_id == context.user.id)
      assert(transaction.amount == Decimal.from_float(-amount))
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.to == context.to)
      assert(transaction.balance == Decimal.new(0))

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_created_event,
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end

    mocked_test "Works correctly when amount with comma", context do
      #  FYI: /add 50,23 Something great
      amount = "50,23"

      reply_payload =
        Pipelines.call(%MessageData{
          message: "#{@add_message} #{amount} #{context.to}",
          chat_id: context.user.telegram_chat_id
        })

      transaction = reply_payload[:transaction]

      assert(%Transaction{} = transaction)
      assert(transaction.user_id == context.user.id)
      assert(transaction.amount == Decimal.from_float(-50.23))
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.to == context.to)
      assert(transaction.balance == Decimal.new(0))

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_created_event,
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end
end
