defmodule MarkevichMoney.Pipelines.Limits.MessagesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.Gamification.TransactionCategoryLimit
  alias MarkevichMoney.{MessageData, Pipelines}
  alias MarkevichMoney.Steps.Limits.RenderLimitsValues, as: Render

  describe "#{@limits_message} message" do
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

    defmock MarkevichMoney.Steps.Limits.RenderLimitsValues do
      def call(_) do
        :passthrough
      end
    end

    mocked_test "Renders limits message", context do
      reply_payload =
        Pipelines.call(%MessageData{message: @limits_message, current_user: context.user})

      assert_called(Render.call(_))
      assert(Map.has_key?(reply_payload, :output_message))

      assert(Map.has_key?(reply_payload, :limits))
      assert(Enum.count(reply_payload[:limits]) == 3)

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          _,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "#{@limit_message} message" do
    setup do
      user = insert(:user)
      category = insert(:transaction_category, name: "Какое-то Название Категории")
      user_input_category_name = "назван"
      new_limit = 100

      %{
        user: user,
        category: category,
        user_input_category_name: user_input_category_name,
        new_limit: new_limit
      }
    end

    mocked_test "Sets the limit with correct message", context do
      message = "#{@limit_message} #{context.user_input_category_name} #{context.new_limit}"
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
        На категорию #{context.category.name} установлен лимит #{context.new_limit}
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )
    end

    mocked_test "Returns support message if input message is invalid", context do
      message = "#{@limit_message} blabla blabla"
      Pipelines.call(%MessageData{message: message, current_user: context.user})

      expected_message = """
      Я не смог распознать эту команду

      Пример правильной команды:
      *#{@limit_message} Еда 150*
        - Еда - это *название* категории, которую можно подсмотреть с помощью команды #{
        @limits_message
      }
        - *150* - это целочисленное значение лимита
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
