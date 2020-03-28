defmodule MarkevichMoney.Stats.GeneralTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines

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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"pipeline\":\"stats\",\"type\":\"c_week\"}",
              switch_inline_query: nil,
              text: "Home",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"pipeline\":\"stats\",\"type\":\"c_week\"}",
              switch_inline_query: nil,
              text: "Food",
              url: nil
            }
          ]
        ]
      }

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
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
          reply_markup: %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: []},
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"pipeline\":\"stats\",\"type\":\"c_month\"}",
              switch_inline_query: nil,
              text: "Home",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"pipeline\":\"stats\",\"type\":\"c_month\"}",
              switch_inline_query: nil,
              text: "Food",
              url: nil
            }
          ]
        ]
      }

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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
      Детализированная статистика 👇👇
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category2.id},\"pipeline\":\"stats\",\"type\":\"p_month\"}",
              switch_inline_query: nil,
              text: "Home",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"c_id\":#{context.category1.id},\"pipeline\":\"stats\",\"type\":\"p_month\"}",
              switch_inline_query: nil,
              text: "Food",
              url: nil
            }
          ]
        ]
      }

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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
      Детализированная статистика 👇👇
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
end
