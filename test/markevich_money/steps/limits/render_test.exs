defmodule MarkevichMoney.Steps.Limits.RenderTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.Constants

  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.Steps.Limits.Render

  describe ".call" do
    setup do
      user = insert(:user)
      category_without_limit = insert(:transaction_category, id: -3, name: "limit_cat1")
      category_with_limit = insert(:transaction_category, id: -2, name: "limit_cat2")
      category_with_0_limit = insert(:transaction_category, id: -1, name: "limit_cat3")

      insert(:transaction_category_limit,
        transaction_category: category_with_limit,
        user: user,
        limit: 125
      )

      limits = Gamifications.list_categories_limits(user)

      %{
        user: user,
        limits: limits,
        category_without_limit: category_without_limit,
        category_with_limit: category_with_limit,
        category_with_0_limit: category_with_0_limit
      }
    end

    test "Renders limits message", context do
      reply_payload = Render.call(%{limits: context.limits})
      assert(Map.has_key?(reply_payload, :output_message))

      assert(
        reply_payload[:output_message] == """
        ```
          Лимиты по категориям

         id   Категория    Лимит

         #{context.category_without_limit.id}   #{context.category_without_limit.name}   ♾️
         #{context.category_with_limit.id}   #{context.category_with_limit.name}   125
         #{context.category_with_0_limit.id}   #{context.category_with_0_limit.name}   ♾️

        ```
        Для установки лимита используйте:

        *#{@set_limit_message} id value*
        """
      )
    end
  end
end
