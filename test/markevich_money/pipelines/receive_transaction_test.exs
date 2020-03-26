defmodule MarkevichMoney.Pipelines.ReceiveTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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
