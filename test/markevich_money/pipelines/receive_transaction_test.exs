defmodule MarkevichMoney.Pipelines.ReceiveTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use Oban.Testing, repo: MarkevichMoney.Repo
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  describe "Карта message without category" do
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

    mocked_test "insert transaction, fire event", context do
      reply_payload =
        Pipelines.call(%MessageData{
          message: context.input_message,
          chat_id: context.user.telegram_chat_id
        })

      transaction = reply_payload[:transaction]

      assert(%Transaction{} = transaction)
      assert(transaction.user_id == context.user.id)
      assert(transaction.amount == Decimal.from_float(-context.amount))
      assert(transaction.transaction_category_id == nil)
      assert(transaction.to == context.to)
      assert(transaction.balance == Decimal.from_float(context.balance))

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: "transaction_created",
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end

  describe "Карта message with category" do
    setup do
      user = insert(:user)
      amount = 11.30
      balance = 522.05
      to = "BLR/MINSK/PIZZERIA PIZZA TEMPO"
      currency = "BYN"

      category = insert(:transaction_category)

      # TODO: write separated tests for predictions
      insert(:transaction,
        to: to,
        user: user,
        transaction_category_id: category.id
      )

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
        to: to,
        category: category
      }
    end

    mocked_test "insert transaction with category, fire event", context do
      reply_payload =
        Pipelines.call(%MessageData{
          message: context.input_message,
          chat_id: context.user.telegram_chat_id
        })

      transaction = reply_payload[:transaction]

      assert(%Transaction{} = transaction)
      assert(transaction.user_id == context.user.id)
      assert(transaction.amount == Decimal.from_float(-context.amount))
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.to == context.to)
      assert(transaction.balance == Decimal.from_float(context.balance))

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: "transaction_created",
          transaction_id: transaction.id,
          user_id: context.user.id
        }
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

      reply_markup = Pipelines.call(message_data)

      refute(Map.has_key?(reply_markup, :transaction))
    end
  end

  # TODO: Incorrect behaviour. Fix it later
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

      category = insert(:transaction_category)

      # prediction
      insert(:transaction,
        to: to,
        transaction_category_id: category.id
      )

      %{
        user: user,
        input_message: input_message,
        amount: amount,
        currency: currency,
        balance: balance,
        to: to,
        category: category
      }
    end

    mocked_test "insert transaction with category, fire event", context do
      reply_payload =
        Pipelines.call(%MessageData{
          message: context.input_message,
          chat_id: context.user.telegram_chat_id
        })

      transaction = reply_payload[:transaction]

      assert(%Transaction{} = transaction)
      assert(transaction.user_id == context.user.id)
      assert(transaction.amount == Decimal.from_float(-context.amount))
      assert(transaction.transaction_category_id == context.category.id)
      assert(transaction.to == context.to)
      assert(transaction.balance == Decimal.from_float(context.balance))

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert_called(Nadia.send_message(context.user.telegram_chat_id, _, _))

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: "transaction_created",
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end
end
