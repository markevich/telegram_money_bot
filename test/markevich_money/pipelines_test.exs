defmodule MarkevichMoney.PipelinesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  defmock Nadia, preserve: true do
    def send_message(_chat_id, _message, _opts) do
    end

    def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
    end

    def answer_callback_query(_callback_id, _options) do
    end
  end

  describe "when unauthorized message data" do
    mocked_test "renders unauthorized message" do
      Pipelines.call(%MessageData{chat_id: -1, current_user: nil})

      assert_called(Nadia.send_message(-1, "Unauthorized", parse_mode: "Markdown"))
    end
  end

  describe "choose_category callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)
      category1 = insert(:transaction_category, name: "Food")
      category2 = insert(:transaction_category, name: "Home")

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"id" => transaction.id, "pipeline" => "choose_category"},
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
         category1: category1,
         category2: category2,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "renders categories to choose from", context do
      transaction = context.transaction
      Pipelines.call(context.callback_data)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{transaction.amount} #{transaction.currency_code}
       Категория
       Кому        #{transaction.target}
       Остаток     #{transaction.balance}
       Дата        #{Timex.format!(transaction.datetime, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"id\":#{transaction.id},\"pipeline\":\"set_category\"}",
              switch_inline_query: nil,
              text: context.category1.name,
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"id\":#{transaction.id},\"pipeline\":\"set_category\"}",
              switch_inline_query: nil,
              text: context.category2.name,
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          nil,
          expected_message,
          reply_markup: expected_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "set_category callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)
      insert(:transaction_category, name: "Food")
      category = insert(:transaction_category, name: "Home")

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => "set_category",
          "c_id" => category.id
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
         chosen_category: category,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "sets the transaction category", context do
      transaction = context.transaction
      Pipelines.call(context.callback_data)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{transaction.amount} #{transaction.currency_code}
       Категория   #{context.chosen_category.name}
       Кому        #{transaction.target}
       Остаток     #{transaction.balance}
       Дата        #{Timex.format!(transaction.datetime, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            },
          ]
        ]
      }

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          nil,
          expected_message,
          reply_markup: expected_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "current week stats callback" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Food")
      category2 = insert(:transaction_category, name: "Home")

      transaction1 =
        insert(:transaction,
          user_id: user.id,
          amount: -10,
          datetime: Timex.shift(Timex.now(), days: -6),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user_id: user.id,
          amount: -15,
          datetime: Timex.now(),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user_id: user.id,
        amount: -105,
        datetime: Timex.shift(Timex.now(), days: -20),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "stats", "type" => "c_week"},
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: "Выберите тип"
      }

      {:ok,
       %{
         user: user,
         callback_data: callback_data,
         category1: category1,
         category2: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "current week stats callback", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.shift(Timex.now(), days: -7)
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:   25.0

       #{context.category2.name}     15.0
       #{context.category1.name}     10.0

      ```
      """

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          nil,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "current month stats callback" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Food")
      category2 = insert(:transaction_category, name: "Home")

      transaction1 =
        insert(:transaction,
          user_id: user.id,
          amount: -10,
          datetime: Timex.beginning_of_month(Timex.now()),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user_id: user.id,
          amount: -15,
          datetime: Timex.end_of_month(Timex.now()),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user_id: user.id,
        amount: -105,
        datetime: Timex.shift(Timex.now(), days: -45),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "stats", "type" => "c_month"},
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: "Выберите тип"
      }

      {:ok,
       %{
         user: user,
         callback_data: callback_data,
         category1: category1,
         category2: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "current week stats callback", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.beginning_of_month(Timex.now())
      stat_to = Timex.end_of_month(Timex.now())
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:   25.0

       #{context.category2.name}     15.0
       #{context.category1.name}     10.0

      ```
      """

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          nil,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "previous month stats callback" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Food")
      category2 = insert(:transaction_category, name: "Home")

      previous_month = Timex.shift(Timex.now(), months: -1)

      transaction1 =
        insert(:transaction,
          user_id: user.id,
          amount: -10,
          datetime: Timex.beginning_of_month(previous_month),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user_id: user.id,
          amount: -15,
          datetime: Timex.end_of_month(previous_month),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user_id: user.id,
        amount: -105,
        datetime: Timex.now(),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "stats", "type" => "p_month"},
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: "Выберите тип"
      }

      {:ok,
       %{
         user: user,
         callback_data: callback_data,
         category1: category1,
         category2: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "current week stats callback", context do
      Pipelines.call(context.callback_data)

      previous_month = Timex.shift(Timex.now(), months: -1)
      stat_from = Timex.beginning_of_month(previous_month)
      stat_to = Timex.end_of_month(previous_month)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:   25.0

       #{context.category2.name}     15.0
       #{context.category1.name}     10.0

      ```
      """

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          nil,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "all stats callback" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Food")
      category2 = insert(:transaction_category, name: "Home")

      transaction1 =
        insert(:transaction,
          user_id: user.id,
          amount: -10,
          datetime: Timex.shift(Timex.now(), years: -1),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user_id: user.id,
          amount: -15,
          datetime: Timex.now(),
          transaction_category_id: category2.id
        )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "stats", "type" => "all"},
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: "Выберите тип"
      }

      {:ok,
       %{
         user: user,
         callback_data: callback_data,
         category1: category1,
         category2: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "current week stats callback", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.parse!("2000-01-01T00:00:00+0000", "{ISO:Extended}")
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:   25.0

       #{context.category2.name}     15.0
       #{context.category1.name}     10.0

      ```
      """

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          nil,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end
end
