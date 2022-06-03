defmodule MarkevichMoney.Pipelines.EditDescriptionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo
  use MarkevichMoney.Constants
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Steps.Transaction.RenderTransaction
  alias MarkevichMoney.Transactions.Transaction

  describe "Reply to message with transaction" do
    setup do
      user = insert(:user)
      category = insert(:transaction_category)

      transaction =
        insert(:transaction,
          user: user,
          to: "Something great",
          amount: -10,
          transaction_category: category
        )

      transaction_renderer = RenderTransaction.call(%{transaction: transaction})

      rendered_transaction = transaction_renderer[:output_message]

      %{transaction: transaction, rendered_transaction: rendered_transaction, user: user}
    end

    mocked_test "edit description", context do
      new_description = "My new description"

      reply_payload =
        Pipelines.call(%MessageData{
          message: new_description,
          chat_id: context.transaction.user.telegram_chat_id,
          reply_to_message: context.rendered_transaction
        })

      transaction = reply_payload.transaction

      assert(%Transaction{} = transaction)
      assert(transaction.custom_description == new_description)

      assert(Map.has_key?(reply_payload, :output_message))
      assert(reply_payload.output_message =~ new_description)
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))
    end
  end

  describe "When replied to non transaction message" do
    setup do
      user = insert(:user)
      message = "Random message"

      %{user: user, message: message}
    end

    mocked_test "edit description", context do
      new_description = "My new description"

      reply_payload =
        Pipelines.call(%MessageData{
          message: new_description,
          chat_id: context.user.telegram_chat_id,
          reply_to_message: context.message
        })

      assert(reply_payload.output_message =~ "бот не смог распознать твой ответ")

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))
    end
  end
end
