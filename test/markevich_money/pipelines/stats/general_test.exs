defmodule MarkevichMoney.Stats.GeneralTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines

  defmock Nadia, preserve: true do
    def send_message(_chat_id, _message, _opts) do
      {:ok, nil}
    end

    def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      {:ok, nil}
    end

    def send_photo(_chat_id, _photo, _opts) do
      {:ok, nil}
    end

    def answer_callback_query(_callback_id, _options) do
      :ok
    end
  end

  describe "current week stats callback" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Food")
      category2 = insert(:transaction_category, name: "Home")

      transaction1 =
        insert(:transaction,
          user: user,
          amount: -10,
          issued_at: Timex.shift(Timex.now(), days: -6),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          amount: -15,
          issued_at: Timex.now(),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user: user,
        amount: -105,
        issued_at: Timex.shift(Timex.now(), days: -20),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_current_week},
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
      updated_payload = Pipelines.call(context.callback_data)

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

      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_current_week}\"}",
              switch_inline_query: nil,
              text: "Food",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_current_week}\"}",
              switch_inline_query: nil,
              text: "Home",
              url: nil
            }
          ]
        ]
      }

      assert(updated_payload.output_message == expected_message)
      assert(updated_payload.reply_markup == expected_markup)

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          reply_markup: expected_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "stats callback without existing transactions" do
    setup do
      user = insert(:user)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_current_week},
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
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "renders 'no transactions' message", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.shift(Timex.now(), days: -7)
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = "Отсутствуют транзакции за период с #{from} по #{to}."

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
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
          user: user,
          amount: -10,
          issued_at: Timex.beginning_of_month(Timex.now()),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          amount: -15,
          issued_at: Timex.end_of_month(Timex.now()),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user: user,
        amount: -105,
        issued_at: Timex.shift(Timex.now(), days: -45),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_current_month},
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
      updated_payload = Pipelines.call(context.callback_data)

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

      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_current_month}\"}",
              switch_inline_query: nil,
              text: "Food",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_current_month}\"}",
              switch_inline_query: nil,
              text: "Home",
              url: nil
            }
          ]
        ]
      }

      assert(updated_payload.output_message == expected_message)
      assert(updated_payload.reply_markup == expected_markup)

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          reply_markup: expected_markup,
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
          user: user,
          amount: -10,
          issued_at: Timex.beginning_of_month(previous_month),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          amount: -15,
          issued_at: Timex.end_of_month(previous_month),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user: user,
        amount: -105,
        issued_at: Timex.now(),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_previous_month},
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
      updated_payload = Pipelines.call(context.callback_data)

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

      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_previous_month}\"}",
              switch_inline_query: nil,
              text: "Food",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_previous_month}\"}",
              switch_inline_query: nil,
              text: "Home",
              url: nil
            }
          ]
        ]
      }

      assert(updated_payload.output_message == expected_message)
      assert(updated_payload.reply_markup == expected_markup)

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          reply_markup: expected_markup,
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
          user: user,
          amount: -10,
          issued_at: Timex.shift(Timex.now(), years: -1),
          transaction_category_id: category1.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          amount: -15,
          issued_at: Timex.now(),
          transaction_category_id: category2.id
        )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_lifetime},
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
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "empty category for all time" do
    setup do
      user = insert(:user)
      category = insert(:transaction_category, name: "kek")

      filled_transaction =
        insert(:transaction,
          user: user,
          amount: -10,
          issued_at: Timex.shift(Timex.now(), days: -6),
          transaction_category_id: category.id
        )

      empty_transaction =
        insert(:transaction,
          user: user,
          to: "qwe",
          amount: -15,
          issued_at: Timex.now()
        )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_lifetime},
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
         category: category,
         filled_transaction: filled_transaction,
         empty_transaction: empty_transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "shows all the transactions with empty and non-empty category", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.parse!("2000-01-01T00:00:00+0000", "{ISO:Extended}")
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:           25.0

       ❓Без категории   15.0
       kek              10.0

      ```
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "empty category for month" do
    setup do
      user = insert(:user)
      category = insert(:transaction_category, name: "kek")

      filled_transaction =
        insert(:transaction,
          user: user,
          amount: -10,
          issued_at: Timex.shift(Timex.now(), months: -1),
          transaction_category_id: category.id
        )

      empty_transaction =
        insert(:transaction,
          user: user,
          to: "qwe",
          amount: -15,
          issued_at: Timex.shift(Timex.now(), months: -1)
        )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_previous_month},
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
         category: category,
         filled_transaction: filled_transaction,
         empty_transaction: empty_transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "shows all the transactions with empty and non-empty category", context do
      updated_payload = Pipelines.call(context.callback_data)

      previous_month = Timex.shift(Timex.now(), months: -1)
      stat_from = Timex.beginning_of_month(previous_month)
      stat_to = Timex.end_of_month(previous_month)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:           25.0

       ❓Без категории   15.0
       kek              10.0

      ```

      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category.id},\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_previous_month}\"}",
              switch_inline_query: nil,
              text: "kek",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":null,\"pipeline\":\"#{@stats_callback}\",\"type\":\"#{@stats_callback_previous_month}\"}",
              switch_inline_query: nil,
              text: "❓Без категории",
              url: nil
            }
          ]
        ]
      }

      assert(updated_payload.output_message == expected_message)
      assert(updated_payload.reply_markup == expected_markup)

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          reply_markup: expected_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "Category with folders/all_time" do
    setup do
      user = insert(:user)

      food_folder =
        insert(:transaction_category_folder, name: "StatsFood", has_single_category: false)

      cafe_category =
        insert(:transaction_category, name: "Cafe", transaction_category_folder: food_folder)

      restaraunt_category =
        insert(:transaction_category, name: "Restaraunt", transaction_category_folder: food_folder)

      insert(:transaction, user: user, amount: -10, transaction_category_id: cafe_category.id)

      insert(:transaction,
        user: user,
        amount: -15,
        transaction_category_id: restaraunt_category.id
      )

      home_folder = insert(:transaction_category_folder, name: "Home", has_single_category: false)

      repair_category =
        insert(:transaction_category, name: "Repair", transaction_category_folder: home_folder)

      insert(:transaction, user: user, amount: -20, transaction_category_id: repair_category.id)

      general_category = insert(:transaction_category, name: "Generic")

      insert(:transaction,
        user: user,
        amount: -10,
        issued_at: Timex.shift(Timex.now(), days: -6),
        transaction_category_id: general_category.id
      )

      insert(:transaction,
        user: user,
        to: "qwe",
        amount: -15,
        issued_at: Timex.now()
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => @stats_callback, "type" => @stats_callback_lifetime},
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
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "renders the beautiful tree", context do
      updated_payload = Pipelines.call(context.callback_data)

      stat_from = Timex.parse!("2000-01-01T00:00:00+0000", "{ISO:Extended}")
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = """
      Расходы c `#{from}` по `#{to}`:
      ```

       Всего:           70.0

       StatsFood        = 25.0
        ├Restaraunt     15.0
        └Cafe           10.0
       Home             = 20.0
        └Repair         20.0
       ❓Без категории   15.0
       Generic          10.0

      ```
      """

      assert(updated_payload.output_message == expected_message)

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end
end
