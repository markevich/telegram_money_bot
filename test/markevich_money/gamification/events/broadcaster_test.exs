defmodule MarkevichMoney.Gamification.Events.BroadcasterTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  use Oban.Testing, repo: MarkevichMoney.Repo
  import ExUnit.CaptureLog

  alias MarkevichMoney.Gamification.Events.Broadcaster
  alias MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit, as: LimitTracker

  describe "when event is transaction_created" do
    setup do
      %{
        payload: %{
          "transaction_id" => 1,
          "event" => "transaction_created"
        }
      }
    end

    test "fires LimitTracker", context do
      Broadcaster.perform(context.payload, %{})

      assert_enqueued(
        worker: LimitTracker,
        args: context.payload
      )
    end
  end

  describe "when event is transaction_updated" do
    setup do
      %{
        payload: %{
          "transaction_id" => 1,
          "event" => "transaction_updated"
        }
      }
    end

    test "fires LimitTracker", context do
      Broadcaster.perform(context.payload, %{})

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Trackers.TransactionCategoryLimit,
        args: context.payload
      )
    end
  end

  describe "when event is unknown" do
    defmock Sentry do
      def capture_message(_, _) do
      end
    end

    mocked_test "send message to sentry" do
      assert capture_log(fn ->
               Broadcaster.perform(%{"event" => "foobar"}, %{})

               assert_called(Sentry.capture_message(_, _))
             end) =~ "worker received unknown arguments"
    end
  end
end
