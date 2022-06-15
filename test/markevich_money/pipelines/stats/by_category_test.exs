defmodule MarkevichMoney.Stats.ByCategoryTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines

  describe "stats callback by category without transactions" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "H$me")

      insert(:transaction,
        user: user,
        amount: -10,
        issued_at: Timex.shift(Timex.now(), years: -1),
        transaction_category_id: category1.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "pipeline" => @stats_callback,
          "type" => @stats_callback_current_week,
          "c_id" => category1.id
        },
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

    mocked_test "current week stats callback by category", context do
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

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end

  describe "current week stats callback by category" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "H$me")
      category2 = insert(:transaction_category, name: "Nomi")

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
          to: "Nomis",
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
        callback_data: %{
          "pipeline" => @stats_callback,
          "type" => @stats_callback_current_week,
          "c_id" => category2.id
        },
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
        Всего: 70.00

       55.00   #{context.transaction2.to}   #{transaction2_issued_at}
       15.00   #{context.transaction1.to}   #{transaction1_issued_at}

      ```
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end

  describe "current month stats callback by category" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "H$me")
      category2 = insert(:transaction_category, name: "Nomi")

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
          to: "Nomis",
          amount: -55,
          issued_at: Timex.shift(Timex.now(), hours: -1),
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
        callback_data: %{
          "pipeline" => @stats_callback,
          "type" => @stats_callback_current_month,
          "c_id" => category2.id
        },
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
        Всего: 70.00

       55.00   #{context.transaction2.to}   #{transaction2_issued_at}
       15.00   #{context.transaction1.to}   #{transaction1_issued_at}

      ```
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end

  describe "previous month stats callback by category" do
    setup do
      user = insert(:user)
      category1 = insert(:transaction_category, name: "H$me")
      category2 = insert(:transaction_category, name: "Nomi")

      previous_month = Timex.beginning_of_month(Timex.shift(Timex.now(), months: -1))

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
          to: "Nomis",
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
        callback_data: %{
          "pipeline" => @stats_callback,
          "type" => @stats_callback_previous_month,
          "c_id" => category2.id
        },
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
        Всего: 70.00

       55.00   #{context.transaction2.to}   #{transaction2_issued_at}
       15.00   #{context.transaction1.to}   #{transaction1_issued_at}

      ```
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end

  describe "stats callback by category without existing transactions" do
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

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end

  describe "previous month stats callback by empty category" do
    setup do
      user = insert(:user)
      category = insert(:transaction_category, name: "H$me")

      previous_month = Timex.beginning_of_month(Timex.shift(Timex.now(), months: -1))

      transaction1 =
        insert(:transaction,
          user: user,
          amount: -10,
          issued_at: previous_month
        )

      insert(:transaction,
        user: user,
        to: "Nomis",
        amount: -55,
        issued_at: previous_month,
        transaction_category_id: category.id
      )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "pipeline" => @stats_callback,
          "type" => @stats_callback_previous_month,
          "c_id" => nil
        },
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
         transaction1: transaction1,
         category: category,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "previous month stats callback by empty category", context do
      Pipelines.call(context.callback_data)

      previous_month = Timex.shift(Timex.now(), months: -1)
      stat_from = Timex.beginning_of_month(previous_month)
      stat_to = Timex.end_of_month(previous_month)
      from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
      to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

      transaction1_issued_at =
        Timex.format!(context.transaction1.issued_at, "{0D}.{0M} {h24}:{m}")

      expected_message = """
      Расходы "❓Без категории" c `#{from}` по `#{to}`:
      ```
        Всего: 10.00

       10.00   #{context.transaction1.to}   #{transaction1_issued_at}

      ```
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end

  describe "stats callback by category with custom description" do
    setup do
      user = insert(:user)
      category2 = insert(:transaction_category, name: "Nomi")

      transaction1 =
        insert(:transaction,
          user: user,
          to: "Pizza",
          amount: -15,
          issued_at: Timex.now(),
          transaction_category_id: category2.id,
          custom_description: "My nomi nomi"
        )

      transaction2 =
        insert(:transaction,
          user: user,
          to: "Nomis",
          amount: -55,
          issued_at: Timex.shift(Timex.now(), days: -1),
          transaction_category_id: category2.id
        )

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "pipeline" => @stats_callback,
          "type" => @stats_callback_current_week,
          "c_id" => category2.id
        },
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
        Всего: 70.00

       55.00   #{context.transaction2.to}          #{transaction2_issued_at}
       15.00   #{context.transaction1.custom_description}   #{transaction1_issued_at}

      ```
      """

      assert_called(
        Nadia.send_message(
          context.user.telegram_chat_id,
          expected_message,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end
end
