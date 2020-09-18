defmodule MarkevichMoney.Pipelines.Limits.CallbacksTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.{CallbackData, Pipelines}
  alias MarkevichMoney.Steps.Limits.RenderLimitsStats

  describe "#{@limits_stats_callback} callback" do
    setup do
      user = insert(:user)
      user2 = insert(:user)
      insert(:transaction_category, name: "Food")
      home_category = insert(:transaction_category, name: "HomeCbTest")
      food_category = insert(:transaction_category, name: "FoodCbTest")

      insert(:transaction, amount: 50, user: user)

      transaction =
        insert(:transaction, transaction_category: home_category, amount: -100, user: user)

      insert(:transaction, transaction_category: home_category, amount: -150, user: user2)

      home_limit =
        insert(:transaction_category_limit,
          transaction_category: home_category,
          limit: 200,
          user: user
        )

      food_limit =
        insert(:transaction_category_limit,
          transaction_category: food_category,
          limit: 100,
          user: user
        )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "pipeline" => @limits_stats_callback
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
         home_category: home_category,
         food_category: food_category,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id,
         home_limit: home_limit,
         food_limit: food_limit
       }}
    end

    defmock MarkevichMoney.Steps.Limits.RenderLimitsStats do
      def call(_) do
        :passthrough
      end
    end

    mocked_test "Send limits stats message", context do
      reply_payload = Pipelines.call(context.callback_data)

      assert_called(RenderLimitsStats.call(_))
      assert(Map.has_key?(reply_payload, :output_message))

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          _,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end
end
