defmodule MarkevichMoney.Steps.Limits.RenderLimitsStatsTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.Constants

  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.Steps.Limits.RenderLimitsStats, as: Render

  describe "Non empty limits" do
    setup do
      user = insert(:user)
      food_folder = insert(:transaction_category_folder, name: "Food", has_single_category: false)

      cafe_category =
        insert(:transaction_category, name: "Cafe", transaction_category_folder: food_folder)

      restaraunt_category =
        insert(:transaction_category, name: "Restaraunt", transaction_category_folder: food_folder)

      transport_folder =
        insert(:transaction_category_folder, name: "Transport", has_single_category: false)

      insert(:transaction_category, name: "Taxi", transaction_category_folder: transport_folder)
      insert(:transaction_category, name: "Car", transaction_category_folder: transport_folder)

      home_category = insert(:transaction_category, name: "HomeCbTest")
      insert(:transaction_category, name: "FoodCbTest")
      health_category = insert(:transaction_category, name: "HealthCbTest")

      insert(:transaction, amount: 50, user: user)

      insert(:transaction, transaction_category: home_category, amount: -100, user: user)

      insert(:transaction_category_limit,
        transaction_category: home_category,
        limit: 200,
        user: user
      )

      insert(:transaction_category_limit,
        transaction_category: restaraunt_category,
        limit: 500,
        user: user
      )

      insert(:transaction_category_limit,
        transaction_category: cafe_category,
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
         payload: payload
       }}
    end

    test "renders limits stats", context do
      reply_payload = Render.call(context.payload)

      assert(Map.has_key?(reply_payload, :output_message))

      expected_message = """
      ```
         Расходы за текущий месяц

       Категория      Расходы

       Food
        ├Cafe         0.00 из 100
        └Restaraunt   0.00 из 500
       HomeCbTest     100.00 из 200

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
