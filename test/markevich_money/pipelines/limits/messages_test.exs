defmodule MarkevichMoney.Pipelines.Limits.MessagesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "/limits message" do
    setup do
      user = insert(:user)
      unrelated_user = insert(:user)
      category_without_limit = insert(:transaction_category, name: "limit_cat1")
      category_with_limit = insert(:transaction_category, name: "limit_cat2")
      category_with_0_limit = insert(:transaction_category, name: "limit_cat3")

      insert(:transaction_category_limit,
        transaction_category: category_with_limit,
        user: user,
        limit: 125
      )

      insert(:transaction_category_limit,
        transaction_category: category_with_0_limit,
        user: user,
        limit: 0
      )

      insert(:transaction_category_limit,
        transaction_category: category_with_limit,
        user: unrelated_user,
        limit: 0
      )

      %{
        user: user,
        category_without_limit: category_without_limit,
        category_with_limit: category_with_limit,
        category_with_0_limit: category_with_0_limit
      }
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
    end

    mocked_test "Renders limits message", context do
      expected_message = """
      ```
         Лимиты по категориям

       id     Категория    Лимит

       #{context.category_without_limit.id}   #{context.category_without_limit.name}   ♾️
       #{context.category_with_limit.id}   #{context.category_with_limit.name}   125
       #{context.category_with_0_limit.id}   #{context.category_with_0_limit.name}   ♾️

      ```
      Для установки лимита используйте:

      */set_limit id value*
      """

      Pipelines.call(%MessageData{message: "/limits", current_user: context.user})

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )
    end
  end
end
