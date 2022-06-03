defmodule MarkevichMoney.PriorbankTest do
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo

  alias MarkevichMoney.Priorbank
  alias MarkevichMoney.Transactions.CreateTransactionWorker

  describe "fetch_latest_transactions" do
    defmock MarkevichMoney.Priorbank.Integration do
      def fetch_priorbank_transactions(_) do
      end

      def convert_to_readable_transaction_attributes(_) do
        [
          %{
            attr: "value1"
          },
          %{
            attr: "value2"
          }
        ]
      end
    end

    mocked_test "it fetches the priorbank data and schedule a transactions creation with given data" do
      connection = insert(:priorbank_connection)

      Priorbank.fetch_latest_transactions(connection)

      assert_enqueued(
        worker: CreateTransactionWorker,
        args: %{
          transaction_attributes: %{"attr" => "value1", "user_id" => connection.user_id},
          source: :priorbank
        }
      )

      assert_enqueued(
        worker: CreateTransactionWorker,
        args: %{
          transaction_attributes: %{"attr" => "value2", "user_id" => connection.user_id},
          source: :priorbank
        }
      )
    end
  end
end
