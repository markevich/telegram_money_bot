defmodule MarkevichMoney.PipelinesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  defmock Nadia, preserve: true do
    def send_message(_chat_id, _message, _opts) do
    end

    def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
    end

    def answer_callback_query(_callback_id, _options) do
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
       Кому        #{transaction.to}
       Остаток     #{transaction.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

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
       Кому        #{transaction.to}
       Остаток     #{transaction.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
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

    mocked_test "renders 'no transactions' message", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.shift(Timex.now(), days: -7)
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = "Отсутствуют транзакции за период с #{from} по #{to}."

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

  describe "current week stats callback by category" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Home")
      category2 = insert(:transaction_category, name: "Food")

      insert(:transaction,
        user: user,
        amount: -10,
        issued_at: Timex.shift(Timex.now(), days: -6),
        transaction_category_id: category1.id
      )

      transaction1 =
        insert(:transaction,
          user: user,
          to: "Pizza",
          amount: -15,
          issued_at: Timex.now(),
          transaction_category_id: category2.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          to: "Foods",
          amount: -55,
          issued_at: Timex.shift(Timex.now(), days: -1),
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
        callback_data: %{"pipeline" => "stats", "type" => "c_week", "c_id" => category2.id},
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
         category: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "current week stats callback by category", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.shift(Timex.now(), days: -7)
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      transaction1_issued_at =
        Timex.format!(context.transaction1.issued_at, "{0D}.{0M} {h24}:{m}")

      transaction2_issued_at =
        Timex.format!(context.transaction2.issued_at, "{0D}.{0M} {h24}:{m}")

      expected_message = """
      Расходы "#{context.category.name}" c `#{from}` по `#{to}`:
      ```
        Всего: 70.0

       55.0   #{context.transaction2.to}   #{transaction2_issued_at}
       15.0   #{context.transaction1.to}   #{transaction1_issued_at}

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

  describe "current month stats callback by category" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Home")
      category2 = insert(:transaction_category, name: "Food")

      insert(:transaction,
        user: user,
        amount: -10,
        issued_at: Timex.shift(Timex.now(), days: -6),
        transaction_category_id: category1.id
      )

      transaction1 =
        insert(:transaction,
          user: user,
          to: "Pizza",
          amount: -15,
          issued_at: Timex.now(),
          transaction_category_id: category2.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          to: "Foods",
          amount: -55,
          issued_at: Timex.shift(Timex.now(), days: -1),
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user: user,
        amount: -105,
        issued_at: Timex.shift(Timex.now(), days: -40),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "stats", "type" => "c_month", "c_id" => category2.id},
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
         category: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "current month stats callback by category", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.beginning_of_month(Timex.now())
      stat_to = Timex.end_of_month(Timex.now())
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      transaction1_issued_at =
        Timex.format!(context.transaction1.issued_at, "{0D}.{0M} {h24}:{m}")

      transaction2_issued_at =
        Timex.format!(context.transaction2.issued_at, "{0D}.{0M} {h24}:{m}")

      expected_message = """
      Расходы "#{context.category.name}" c `#{from}` по `#{to}`:
      ```
        Всего: 70.0

       55.0   #{context.transaction2.to}   #{transaction2_issued_at}
       15.0   #{context.transaction1.to}   #{transaction1_issued_at}

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

  describe "previous month stats callback by category" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "Home")
      category2 = insert(:transaction_category, name: "Food")

      previous_month = Timex.shift(Timex.now(), months: -1)

      insert(:transaction,
        user: user,
        amount: -10,
        issued_at: previous_month,
        transaction_category_id: category1.id
      )

      transaction1 =
        insert(:transaction,
          user: user,
          to: "Pizza",
          amount: -15,
          issued_at: Timex.shift(previous_month, days: 5),
          transaction_category_id: category2.id
        )

      transaction2 =
        insert(:transaction,
          user: user,
          to: "Foods",
          amount: -55,
          issued_at: previous_month,
          transaction_category_id: category2.id
        )

      insert(:transaction,
        user: user,
        amount: -105,
        issued_at: Timex.shift(previous_month, months: -1),
        transaction_category_id: category2.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "stats", "type" => "p_month", "c_id" => category2.id},
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
         category: category2,
         transaction1: transaction1,
         transaction2: transaction2,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "previous month stats callback by category", context do
      Pipelines.call(context.callback_data)

      previous_month = Timex.shift(Timex.now(), months: -1)
      stat_from = Timex.beginning_of_month(previous_month)
      stat_to = Timex.end_of_month(previous_month)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      transaction1_issued_at =
        Timex.format!(context.transaction1.issued_at, "{0D}.{0M} {h24}:{m}")

      transaction2_issued_at =
        Timex.format!(context.transaction2.issued_at, "{0D}.{0M} {h24}:{m}")

      expected_message = """
      Расходы "#{context.category.name}" c `#{from}` по `#{to}`:
      ```
        Всего: 70.0

       55.0   #{context.transaction2.to}   #{transaction2_issued_at}
       15.0   #{context.transaction1.to}   #{transaction1_issued_at}

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

  describe "stats callback by category without existing transactions" do
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

    mocked_test "renders 'no transactions' message", context do
      Pipelines.call(context.callback_data)

      stat_from = Timex.shift(Timex.now(), days: -7)
      stat_to = Timex.shift(Timex.now(), days: 1)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      expected_message = "Отсутствуют транзакции за период с #{from} по #{to}."

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

  describe "unknown callback pipelines" do
    setup do
      user = insert(:user)
      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{"pipeline" => "_unknown"},
        callback_id: callback_id,
        chat_id: user.telegram_chat_id,
        current_user: user,
        message_id: message_id,
        message_text: ""
      }

      %{callback_data: callback_data}
    end

    test "does nothing", %{callback_data: callback_data} do
      result = Pipelines.call(callback_data)

      assert(result == callback_data)
    end
  end

  describe "message data with username" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "puts current user into payload when user exists", %{user: user} do
      message_data = %MessageData{
        username: user.name,
        message: ""
      }

      result = Pipelines.call(message_data)

      assert(%{current_user: current_user} = result)
      assert(current_user == user)
    end

    test "does nothing when user is not exists" do
      message_data = %MessageData{
        username: "_PWNED",
        message: ""
      }

      result = Pipelines.call(message_data)

      assert(%{current_user: nil} = result)
    end
  end

  describe "message data with chat_id" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "puts current user into payload when user exists", %{user: user} do
      message_data = %MessageData{
        chat_id: user.telegram_chat_id,
        message: ""
      }

      result = Pipelines.call(message_data)

      assert(%{current_user: current_user} = result)
      assert(current_user == user)
    end

    mocked_test "renders unauthorized message when user is not exists" do
      Pipelines.call(%MessageData{chat_id: -1, current_user: nil})

      assert_called(Nadia.send_message(-1, "Unauthorized", parse_mode: "Markdown"))
    end
  end

  describe "callback data with chat_id" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "puts current user into payload when user exists", %{user: user} do
      callback_data = %CallbackData{
        chat_id: user.telegram_chat_id,
        callback_data: %{"pipeline" => "_unexisting"}
      }

      result = Pipelines.call(callback_data)

      assert(%{current_user: current_user} = result)
      assert(current_user == user)
    end
  end

  describe "/help message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "Renders help message", %{user: user} do
      expected_message = """
      Я создан помогать Маркевичам следить за своим бюджетом

      /start - Начало работы
      /help - Диалог помощи
      """

      Pipelines.call(%MessageData{message: "/help", chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message, parse_mode: "Markdown")
      )
    end
  end

  describe "/start message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "Renders help message", %{user: user} do
      expected_message = "FIXME or REMOVEME"

      Pipelines.call(%MessageData{message: "/start", chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message, parse_mode: "Markdown")
      )
    end
  end

  describe "/stats message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "Renders stats message", %{user: user} do
      expected_message = "Выберите тип"

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"pipeline\":\"stats\",\"type\":\"c_week\"}",
              switch_inline_query: nil,
              text: "Текущая неделя",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"pipeline\":\"stats\",\"type\":\"c_month\"}",
              switch_inline_query: nil,
              text: "Текущий месяц",
              url: nil
            }
          ],
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"pipeline\":\"stats\",\"type\":\"p_month\"}",
              switch_inline_query: nil,
              text: "Прошлый месяц",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"pipeline\":\"stats\",\"type\":\"all\"}",
              switch_inline_query: nil,
              text: "За все время",
              url: nil
            }
          ]
        ]
      }

      Pipelines.call(%MessageData{message: "/stats", chat_id: user.telegram_chat_id})

      assert_called(
        Nadia.send_message(
          user.telegram_chat_id,
          expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "/add message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "insert and renders transaction", %{user: user} do
      Pipelines.call(%MessageData{message: "/add 50 something", chat_id: user.telegram_chat_id})

      user_id = user.id

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^(-50)
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{transaction.amount} #{transaction.currency_code}
       Категория
       Кому        #{transaction.to}
       Остаток     #{transaction.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "Карта message" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      to = "BLR/MINSK/PIZZERIA PIZZA TEMPO"
      currency = "BYN"

      input_message = """
      Карта 5.9737
      Со счёта: BY06ALFA30143400080030270000
      Оплата товаров/услуг
      Успешно
      Сумма:#{amount} #{currency}
      Остаток:#{balance} #{currency}
      На время:15:14:35
      #{to}
      28.01.2020 15:14:35
      """

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance,
        to: to
      }
    end

    mocked_test "insert and renders transaction", %{user: user} = context do
      Pipelines.call(%MessageData{message: context.input_message, chat_id: user.telegram_chat_id})

      user_id = user.id
      amount = -context.amount

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^amount
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{amount} #{context.currency}
       Категория
       Кому        #{context.to}
       Остаток     #{context.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "unsuccessful Карта message" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      to = "BLR/MINSK/PIZZERIA PIZZA TEMPO"
      currency = "BYN"

      input_message = """
      Карта 5.9737
      Со счёта: BY06ALFA30143400080030270000
      Оплата товаров/услуг
      Отказ
      Сумма:#{amount} #{currency}
      Остаток:#{balance} #{currency}
      На время:15:14:35
      #{to}
      28.01.2020 15:14:35
      """

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance,
        to: to
      }
    end

    mocked_test "do nothing", %{user: user} = context do
      message_data = %MessageData{message: context.input_message, chat_id: user.telegram_chat_id}

      count_before = Repo.aggregate(from(Transaction), :count, :id)
      Pipelines.call(message_data)
      count_after = Repo.aggregate(from(Transaction), :count, :id)

      assert count_before == count_after
    end
  end

  describe "Карта message with converted values" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      to = "BLR/MINSK/PIZZERIA PIZZA TEMPO"
      currency = "BYN"

      input_message = """
      Карта 5.9737
      Со счёта: BY06ALFA30143400080030270000
      Оплата товаров/услуг
      Успешно
      Сумма:1.00 USD (#{amount} #{currency})
      Остаток:#{balance} #{currency}
      На время:15:14:35
      #{to}
      28.01.2020 15:14:35
      """

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance,
        to: to
      }
    end

    mocked_test "insert and renders transaction", %{user: user} = context do
      Pipelines.call(%MessageData{message: context.input_message, chat_id: user.telegram_chat_id})

      user_id = user.id
      amount = -context.amount

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^amount
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{amount} #{context.currency}
       Категория
       Кому        #{context.to}
       Остаток     #{context.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "Карта message with income" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      to = "BLR/MINSK/PIZZERIA PIZZA TEMPO"
      currency = "BYN"

      input_message = """
      Карта 5.9737
      На счёт: BY06ALFA30143400080030270000
      Перевод (Поступление)
      Успешно
      Сумма:#{amount} #{currency}
      Остаток:#{balance} #{currency}
      На время:15:14:35
      #{to}
      28.01.2020 15:14:35
      """

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance,
        to: to
      }
    end

    mocked_test "insert and renders transaction", %{user: user} = context do
      Pipelines.call(%MessageData{message: context.input_message, chat_id: user.telegram_chat_id})

      user_id = user.id
      amount = context.amount

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^amount
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Поступление)
      ```

       Сумма       #{amount} #{context.currency}
       Категория
       Кому        #{context.to}
       Остаток     #{context.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "Карта message with income without time" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      currency = "BYN"

      input_message = """
      Карта 5.9737
      На счёт: BY06ALFA30143400080030270000
      Перевод (Поступление)
      Успешно
      Сумма:#{amount} #{currency}
      Остаток:#{balance} #{currency}
      На время:15:14:35
      28.01.2020
      """

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance
      }
    end

    mocked_test "insert and renders transaction", %{user: user} = context do
      Pipelines.call(%MessageData{message: context.input_message, chat_id: user.telegram_chat_id})

      user_id = user.id
      amount = context.amount

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^amount
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Поступление)
      ```

       Сумма       #{amount} #{context.currency}
       Категория
       Кому        28.01.2020
       Остаток     #{context.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "✉️ <click@alfa-bank.by> message" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      to = "BLR/MINSK/PIZZERIA PIZZA TEMPO"
      currency = "BYN"

      input_message = """
      ✉️ <click@alfa-bank.by>
      5.9737/Оплата товаров/услуг

      Карта 5.9737
      Со счёта: BY06ALFA30143400080030270000
      Оплата товаров/услуг
      Успешно
      Сумма:#{amount} #{currency}
      Остаток:#{balance} #{currency}
      На время:15:14:35
      #{to}
      28.01.2020 15:14:35
      """

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance,
        to: to
      }
    end

    mocked_test "insert and renders transaction", %{user: user} = context do
      Pipelines.call(%MessageData{message: context.input_message, chat_id: user.telegram_chat_id})

      user_id = user.id
      amount = -context.amount

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^amount
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{amount} #{context.currency}
       Категория
       Кому        #{context.to}
       Остаток     #{context.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end

    mocked_test "insert and renders transaction when category is known",
                %{user: user} = context do
      category = insert(:transaction_category)

      insert(:transaction_category_prediction,
        prediction: context.to,
        transaction_category_id: category.id
      )

      Pipelines.call(%MessageData{message: context.input_message, chat_id: user.telegram_chat_id})

      user_id = user.id
      amount = -context.amount

      query =
        from(transaction in Transaction,
          where: transaction.user_id == ^user_id,
          where: transaction.amount == ^amount
        )

      transaction = Repo.one!(query)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{amount} #{context.currency}
       Категория   #{category.name}
       Кому        #{context.to}
       Остаток     #{context.balance}
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data: "{\"id\":#{transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Выбрать категорию",
              url: nil
            }
          ]
        ]
      }

      assert_called(
        Nadia.send_message(user.telegram_chat_id, expected_message,
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )
    end
  end
end
