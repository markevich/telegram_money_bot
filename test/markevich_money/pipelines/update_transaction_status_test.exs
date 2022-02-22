defmodule MarkevichMoney.Pipelines.UpdateTransactionStatusTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Pipelines.RerenderTransaction
  alias MarkevichMoney.Transactions.Transaction

  describe "with @transaction_set_ignored_status_callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => @update_transaction_status_pipeline,
          "action" => @transaction_set_ignored_status_callback
        },
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: "doesn't matter"
      }

      {:ok,
       %{
         user: user,
         callback_data: callback_data,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        :ok
      end
    end

    defmock MarkevichMoney.Pipelines.RerenderTransaction do
      def call(_) do
        :passthrough
      end
    end

    mocked_test "set transaction status to ignored", context do
      transaction = context.transaction
      Pipelines.call(context.callback_data)

      transaction =
        from(t in Transaction, where: t.id == ^transaction.id)
        |> Repo.one!()

      assert(transaction.status == @transaction_status_ignored)

      assert_called(RerenderTransaction.call(_))

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          _,
          _,
          _
        )
      )
    end
  end

  describe "with @transaction_set_normal_status_callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => @update_transaction_status_pipeline,
          "action" => @transaction_set_normal_status_callback
        },
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: "doesn't matter"
      }

      {:ok,
       %{
         user: user,
         callback_data: callback_data,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    defmock Nadia do
      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        :ok
      end
    end

    defmock MarkevichMoney.Pipelines.RerenderTransaction do
      def call(_) do
        :passthrough
      end
    end

    mocked_test "set transaction status to ignored", context do
      transaction = context.transaction
      Pipelines.call(context.callback_data)

      transaction =
        from(t in Transaction, where: t.id == ^transaction.id)
        |> Repo.one!()

      assert(transaction.status == @transaction_status_normal)

      assert_called(RerenderTransaction.call(_))

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          _,
          _,
          _
        )
      )
    end
  end
end
