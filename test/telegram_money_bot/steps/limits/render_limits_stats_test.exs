defmodule TelegramMoneyBot.Steps.Limits.RenderLimitsStatsTest do
  use TelegramMoneyBot.DataCase, async: true
  use TelegramMoneyBot.Constants

  alias TelegramMoneyBot.Gamifications
  alias TelegramMoneyBot.Steps.Limits.RenderLimitsStats, as: Render

  describe "Non empty limits" do
    setup do
      user = insert(:user)
      insert(:transaction_category, name: "Food")
      home_category = insert(:transaction_category, name: "HomeCbTest")
      food_category = insert(:transaction_category, name: "FoodCbTest")
      health_category = insert(:transaction_category, name: "HealthCbTest")

      insert(:transaction, amount: 50, user: user)

      home_transaction =
        insert(:transaction, transaction_category: home_category, amount: -100, user: user)

      home_transaction_amount = abs(Decimal.to_integer(home_transaction.amount))

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

      # 0 limit must not be drawn
      insert(:transaction_category_limit,
        transaction_category: health_category,
        limit: 0,
        user: user
      )

      limits = Gamifications.list_categories_limits(user)

      payload = %{
        current_user: user,
        limits: limits
      }

      {:ok,
       %{
         user: user,
         home_category: home_category,
         food_category: food_category,
         home_transaction_amount: home_transaction_amount,
         home_limit: home_limit,
         food_limit: food_limit,
         payload: payload
       }}
    end

    test "renders limits stats", context do
      reply_payload = Render.call(context.payload)

      assert(Map.has_key?(reply_payload, :output_message))

      expected_message = """
      ```
       Расходы за текущий месяц

       Категория     Расходы

       #{context.home_category.name}    #{context.home_transaction_amount} из #{
        context.home_limit.limit
      }
       #{context.food_category.name}    0 из #{context.food_limit.limit}

      ```
      """

      assert(reply_payload[:output_message] == expected_message)
    end
  end

  describe ".call with empty limits" do
    setup do
      user = insert(:user)
      limits = Gamifications.list_categories_limits(user)

      %{
        user: user,
        limits: limits
      }
    end

    test "Renders empty limits message", context do
      reply_payload = Render.call(%{limits: context.limits, current_user: context.user})
      assert(Map.has_key?(reply_payload, :output_message))

      assert(
        reply_payload[:output_message] == """
        ```
        Отсутствуют установленные лимиты
        ```
        """
      )
    end
  end
end
