defmodule MarkevichMoney.TransactionsTest do
  use MarkevichMoney.DataCase, async: true
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo

  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Transactions.CreateTransactionWorker

  describe "create_from_api" do
    test "enqueues creation worker" do
      Transactions.create_from_api(%{
        amount: "-5",
        currency_code: "USD",
        to: "Test god",
        issued_at: "2023-01-03",
        balance: "100",
        status: "normal",
        account: "tbc"
      })

      assert_enqueued(
        worker: CreateTransactionWorker,
        args: %{
          transaction_attributes: %{
            amount: "-5",
            currency_code: "USD",
            to: "Test god",
            issued_at: "2023-01-03",
            balance: "100",
            status: "normal",
            account: "tbc"
          },
          source: :api_v1
        }
      )
    end
  end
end
