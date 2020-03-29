defmodule MarkevichMoney.Pipelines.Limits.MessagesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.Gamification.TransactionCategoryLimit
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  describe "/limits message" do
    setup do
      user = insert(:user)
      unrelated_user = insert(:user)
      category_without_limit = insert(:transaction_category, id: -3, name: "limit_cat1")
      category_with_limit = insert(:transaction_category, id: -2, name: "limit_cat2")
      category_with_0_limit = insert(:transaction_category, id: -1, name: "limit_cat3")

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
        {:ok, nil}
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        {:ok, nil}
      end
    end

    mocked_test "Renders limits message", context do
      expected_message = """
      ```
        Лимиты по категориям

       id   Категория    Лимит

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

  describe "/set_limit message" do
    setup do
      user = insert(:user)
      category = insert(:transaction_category)
      new_limit = 100

      %{
        user: user,
        category: category,
        new_limit: new_limit
      }
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        {:ok, nil}
      end
    end

    mocked_test "Sets the limit with correct message", context do
      message = "/set_limit #{context.category.id} #{context.new_limit}"
      Pipelines.call(%MessageData{message: message, current_user: context.user})

      query =
        from(l in TransactionCategoryLimit,
          where:
            l.user_id == ^context.user.id and
              l.transaction_category_id == ^context.category.id and
              l.limit == ^context.new_limit
        )

      assert(Repo.exists?(query))

      expected_message = """
      Упешно!

      Нажмите на /limits для просмотра обновленных лимитов
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        {:ok, nil}
      end
    end

    mocked_test "Returns support message if input message is invalid", context do
      message = "/set_limit blabla blabla"
      Pipelines.call(%MessageData{message: message, current_user: context.user})

      expected_message = """
      Я не смог распознать эту команду

      Пример правильной команды:
      */set_limit 1 150*
        - *1* это *id* категории, которую можно подсмотреть с помощью команды /limits
        - *150* это целочисленное значение лимита
      """

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
