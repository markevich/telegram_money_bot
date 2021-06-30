defmodule MarkevichMoney.Steps.Limits.RenderLimitsValuesTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.Constants

  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.Steps.Limits.RenderLimitsValues, as: Render

  describe ".call" do
    setup do
      user = insert(:user)
      insert(:transaction_category, id: -3, name: "limit_cat1")
      category_with_limit = insert(:transaction_category, id: -2, name: "limit_cat2")
      insert(:transaction_category, id: -1, name: "limit_cat3")

      insert(:transaction_category_limit,
        transaction_category: category_with_limit,
        user: user,
        limit: 125
      )

      insert(:transaction,
        transaction_category: category_with_limit,
        user: user,
        amount: 100
      )

      food_folder = insert(:transaction_category_folder, name: "Food", has_single_category: false)

      cafe_category =
        insert(:transaction_category, name: "Cafe", transaction_category_folder: food_folder)

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

      %{
        user: user,
        limits: limits
      }
    end

    test "Renders limits message", context do
      reply_payload = Render.call(%{limits: context.limits, current_user: context.user})
      assert(Map.has_key?(reply_payload, :output_message))

      assert(
        reply_payload[:output_message] == """
        ```

         Лимиты по категориям

         Категория      Лимит

         Food
          ├Cafe         100
          └Restaraunt   ♾️
         Transport
          ├Taxi         ♾️
          └Car          ♾️
         limit_cat1     ♾️
         limit_cat2     125
         limit_cat3     ♾️
         HomeCbTest     200
         FoodCbTest     ♾️
         HealthCbTest   ♾️

        ```
        ```
         Расходы за текущий месяц

         Категория     Расходы

         Food
          └Cafe        0 из 100
         limit_cat2    0 из 125
         HomeCbTest    100 из 200

        ```

        Для установки лимита используйте:

        *#{@limit_message} категория число*
        """
      )
    end
  end
end
