defmodule MarkevichMoney.Transactions.CreateTransactionWorkerTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  use MecksUnit.Case
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo

  import ExUnit.CaptureLog

  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Transactions.CreateTransactionWorker

  describe ".perform with attributes for new transactions" do
    setup do
      category = insert(:transaction_category)

      insert(:transaction, to: "Pizza worker", transaction_category_id: category.id)
      user = insert(:user)

      %{
        user: user,
        attributes: %{
          account: "BYN cards",
          amount: -123,
          currency_code: "BYN",
          balance: "100",
          issued_at: NaiveDateTime.from_iso8601!("2021-05-01T12:41:00"),
          to: "Pizza worker",
          user_id: user.id,
          external_amount: -60,
          external_currency: "USD",
          status: @transaction_status_normal
        },
        category: category
      }
    end

    mocked_test "creates new regular transaction, predict category, fire required events",
                context do
      {:ok, result} =
        CreateTransactionWorker
        |> perform_job(%{"transaction_attributes" => context.attributes})

      transaction = result[:transaction]
      assert(transaction)
      assert(transaction.id)
      assert(transaction.account == context.attributes.account)
      assert(transaction.amount == Decimal.new(context.attributes.amount))
      assert(transaction.currency_code == context.attributes.currency_code)
      assert(transaction.balance == Decimal.new(context.attributes.balance))
      assert(transaction.issued_at)
      assert(transaction.to == context.attributes.to)
      assert(transaction.user_id == context.user.id)
      assert(transaction.external_amount == Decimal.new(context.attributes.external_amount))
      assert(transaction.external_currency == context.attributes.external_currency)
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.status == @transaction_status_normal)

      assert(result[:output_message] =~ "Pizza worker")

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          result[:output_message],
          _
        )
      )

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_created_event,
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end

    mocked_test "creates new fund freeze transaction, predict category, fire required events",
                context do
      attributes = Map.put(context.attributes, :status, @transaction_status_bank_fund_freeze)

      {:ok, result} =
        CreateTransactionWorker
        |> perform_job(%{"transaction_attributes" => attributes})

      transaction = result[:transaction]
      assert(transaction)
      assert(transaction.id)
      assert(transaction.account == context.attributes.account)
      assert(transaction.amount == Decimal.new(context.attributes.amount))
      assert(transaction.currency_code == context.attributes.currency_code)
      assert(transaction.balance == Decimal.new(context.attributes.balance))
      assert(transaction.issued_at)
      assert(transaction.to == context.attributes.to)
      assert(transaction.user_id == context.user.id)
      assert(transaction.external_amount == Decimal.new(context.attributes.external_amount))
      assert(transaction.external_currency == context.attributes.external_currency)
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.status == @transaction_status_bank_fund_freeze)

      assert(result[:output_message] =~ "Pizza worker")

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          result[:output_message],
          _
        )
      )

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

  describe ".perform with attributes for existing regular transaction" do
    setup do
      user = insert(:user)

      account = "BYN cards"
      amount = -100
      issued_at = "2021-05-01T13:41:00"

      lookup_hash = Transactions.calculate_lookup_hash(user.id, account, amount, issued_at)

      attributes_for_existing_transaction = %{
        account: account,
        amount: amount,
        currency_code: "BYN",
        balance: 150,
        issued_at: issued_at,
        to: "Pizza worker existing",
        user: user,
        lookup_hash: lookup_hash
      }

      existing_transaction = insert(:transaction, attributes_for_existing_transaction)

      %{
        attributes_for_new_transaction: %{
          account: account,
          amount: amount,
          currency_code: "BYN",
          balance: 150,
          issued_at: issued_at,
          to: "Pizza worker existing",
          user_id: user.id,
          status: @transaction_status_normal
        },
        existing_transaction: existing_transaction,
        user: user
      }
    end

    test "Does nothing if transaction already exists", context do
      {:ok, result} =
        CreateTransactionWorker
        |> perform_job(%{"transaction_attributes" => context.attributes_for_new_transaction})

      assert(result.transaction.id == context.existing_transaction.id)

      refute_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_created_event,
          transaction_id: context.existing_transaction.id,
          user_id: context.user.id
        }
      )
    end
  end

  describe ".perform with attributes for existing fund freeze transaction" do
    setup do
      user = insert(:user)

      account = "BYN cards"
      amount = -100
      issued_at = "2021-05-01T13:41:00"

      lookup_hash = Transactions.calculate_lookup_hash(user.id, account, amount, issued_at)

      attributes_for_existing_transaction = %{
        account: account,
        amount: amount,
        currency_code: "BYN",
        balance: 150,
        issued_at: issued_at,
        to: "Pizza worker existing",
        user: user,
        lookup_hash: lookup_hash,
        status: @transaction_status_bank_fund_freeze
      }

      existing_transaction = insert(:transaction, attributes_for_existing_transaction)

      %{
        attributes_for_new_transaction: %{
          account: account,
          amount: amount,
          currency_code: "BYN",
          balance: 150,
          issued_at: issued_at,
          to: "Pizza worker existing",
          user_id: user.id,
          status: @transaction_status_bank_fund_freeze
        },
        existing_transaction: existing_transaction,
        user: user
      }
    end

    test "Does nothing if transaction already exists", context do
      {:ok, result} =
        CreateTransactionWorker
        |> perform_job(%{"transaction_attributes" => context.attributes_for_new_transaction})

      assert(result.transaction.id == context.existing_transaction.id)

      refute_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_created_event,
          transaction_id: context.existing_transaction.id,
          user_id: context.user.id
        }
      )
    end
  end

  describe "when payload is unknown" do
    test "sends error message to logger" do
      assert(
        capture_log(fn ->
          assert :ok = perform_job(CreateTransactionWorker, %{"foo" => "bar"})
        end) =~ "worker received unknown arguments"
      )
    end
  end
end
