defmodule MarkevichMoney.Gamification.Trackers.TransactionCategoryLimitTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MecksUnit.Case
  use Oban.Testing, repo: MarkevichMoney.Repo
  import ExUnit.CaptureLog

  alias MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit, as: LimitTracker

  describe "when transaction without transaction_category_id" do
    setup do
      %{transaction: insert(:transaction)}
    end

    test "skip execution", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      refute(Map.has_key?(result, :output_message))
    end
  end

  describe "without category limit" do
    setup do
      category = insert(:transaction_category)
      transaction = insert(:transaction, transaction_category: category)

      %{transaction: transaction}
    end

    test "skip execution", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      refute(Map.has_key?(result, :output_message))
    end
  end

  describe "when category limit is 0" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 0)

      transaction =
        insert(:transaction, user: user, transaction_category: category_limit.transaction_category)

      %{transaction: transaction}
    end

    test "skip execution", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      refute(Map.has_key?(result, :output_message))
    end
  end

  describe "when category limit is 100 and new transaction does not exceeds total 50" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 100)

      transaction =
        insert(:transaction,
          user: user,
          amount: -5,
          transaction_category: category_limit.transaction_category
        )

      insert(:transaction,
        user: user,
        amount: -30,
        transaction_category: category_limit.transaction_category
      )

      %{transaction: transaction}
    end

    mocked_test "skip execution", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      refute(Map.has_key?(result, :output_message))
    end
  end

  describe "when category limit is 100 and new transaction does not jump on current limit 50 <=> 70" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 100)

      transaction =
        insert(:transaction,
          user: user,
          amount: -5,
          transaction_category: category_limit.transaction_category
        )

      insert(:transaction,
        user: user,
        amount: -55,
        transaction_category: category_limit.transaction_category
      )

      %{transaction: transaction}
    end

    mocked_test "skip execution", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      refute(Map.has_key?(result, :output_message))
    end
  end

  describe "when category limit is 100 and new transaction does exceeds total 50" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 100)
      category = category_limit.transaction_category
      transaction = insert(:transaction, user: user, amount: -25, transaction_category: category)
      insert(:transaction, user: user, amount: -30, transaction_category: category)

      %{
        user: user,
        transaction: transaction,
        category: category,
        category_limit: category_limit
      }
    end

    mocked_test "send warning message", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      assert(Map.has_key?(result, :output_message))

      expected_message = """
      *Внимание! В категории \"#{context.category.name}\" потрачено 55% месячного бюджета.*
      ```
      |⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀|
           55% (55/100) BYN
      ```

      """

      assert_called(
        Nadia.send_message(context.user.telegram_chat_id, expected_message, parse_mode: "Markdown")
      )
    end

    test "skips execution if transaction is income", context do
      transaction =
        insert(:transaction,
          user: context.user,
          amount: 25,
          transaction_category: context.category
        )

      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => transaction.id})

      refute(Map.has_key?(result, :output_message))
    end
  end

  describe "when category limit is 100 and new transaction does exceeds total 70" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 100)
      category = category_limit.transaction_category
      transaction = insert(:transaction, user: user, amount: -45, transaction_category: category)
      insert(:transaction, user: user, amount: -30, transaction_category: category)

      %{
        user: user,
        transaction: transaction,
        category: category,
        category_limit: category_limit
      }
    end

    mocked_test "send warning message", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      assert(Map.has_key?(result, :output_message))

      expected_message = """
      *Внимание! В категории \"#{context.category.name}\" потрачено 75% месячного бюджета.*
      ```
      |⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀|
           75% (75/100) BYN
      ```

      """

      assert(result[:output_message] == expected_message)
    end
  end

  describe "when category limit is 100 and new transaction jumps from 70% to > 100%" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 100)
      category = category_limit.transaction_category
      transaction = insert(:transaction, user: user, amount: -45, transaction_category: category)
      insert(:transaction, user: user, amount: -75, transaction_category: category)

      %{
        user: user,
        transaction: transaction,
        category: category,
        category_limit: category_limit
      }
    end

    mocked_test "send warning message", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      assert(Map.has_key?(result, :output_message))

      expected_message = """
      *Внимание! В категории \"#{context.category.name}\" потрачено 120% месячного бюджета.*
      ```
      |⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿|
          120% (120/100) BYN
      ```

      """

      assert(result[:output_message] == expected_message)
    end
  end

  describe "when category limit is 100 and new transaction jumps from 110% to > 120%" do
    setup do
      user = insert(:user)
      category_limit = insert(:transaction_category_limit, user: user, limit: 100)
      category = category_limit.transaction_category
      transaction = insert(:transaction, user: user, amount: -10, transaction_category: category)
      insert(:transaction, user: user, amount: -110, transaction_category: category)

      %{
        user: user,
        transaction: transaction,
        category: category,
        category_limit: category_limit
      }
    end

    mocked_test "send warning message", context do
      {:ok, result} =
        LimitTracker
        |> perform_job(%{"transaction_id" => context.transaction.id})

      assert(Map.has_key?(result, :output_message))

      expected_message = """
      *Внимание! В категории \"#{context.category.name}\" потрачено 120% месячного бюджета.*
      ```
      |⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿|
          120% (120/100) BYN
      ```

      """

      assert(result[:output_message] == expected_message)
    end
  end

  describe "when payload is unknown" do
    test "sends error message to logger" do
      assert(
        capture_log(fn ->
          assert :ok = perform_job(LimitTracker, %{"foo" => "bar"})
        end) =~ "worker received unknown arguments"
      )
    end
  end
end
