defmodule TelegramMoneyBot.Gamification.Events.BroadcasterTest do
  @moduledoc false
  use TelegramMoneyBot.DataCase, async: true
  use MecksUnit.Case
  use Oban.Testing, repo: TelegramMoneyBot.Repo
  use TelegramMoneyBot.Constants
  import ExUnit.CaptureLog

  alias TelegramMoneyBot.Gamification.Events.Broadcaster
  alias TelegramMoneyBot.Gamification.Trackers.TransactionCategoryLimit, as: LimitTracker

  describe "when event is #{@transaction_created_event}" do
    setup do
      %{
        payload: %{
          "transaction_id" => 1,
          "event" => @transaction_created_event
        }
      }
    end

    test "fires LimitTracker", context do
      assert :ok = perform_job(Broadcaster, context.payload)

      assert_enqueued(
        worker: LimitTracker,
        args: context.payload
      )
    end
  end

  describe "when event is #{@transaction_updated_event}" do
    setup do
      %{
        payload: %{
          "transaction_id" => 1,
          "event" => @transaction_updated_event
        }
      }
    end

    test "fires LimitTracker", context do
      assert :ok = perform_job(Broadcaster, context.payload)

      assert_enqueued(
        worker: TelegramMoneyBot.Gamification.Trackers.TransactionCategoryLimit,
        args: context.payload
      )
    end
  end

  describe "when event is unknown" do
    test "sends error message to logger" do
      assert(
        capture_log(fn ->
          assert :ok = perform_job(Broadcaster, %{"event" => "foobar"}, [])
        end) =~ "worker received unknown arguments"
      )
    end
  end
end
