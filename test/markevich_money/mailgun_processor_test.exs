defmodule MarkevichMoney.MailgunProcessorTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.MailgunProcessor
  alias MarkevichMoney.Transactions

  describe "when mail is from known user" do
    setup do
      user = insert(:user)

      mail = %Receivex.Email{
        from: {"doesn't matter", "some.email@gmail.com"},
        html: "",
        sender: nil,
        subject: "adsd",
        text:
          "Карта 5.9737\r\nСо счёта: BY06ALFA30143400080030270000\r\nОплата товаров/услуг\r\nУспешно\r\nСумма:18.26 BYN\r\nОстаток:450.56 BYN\r\nНа время:15:08:56\r\nBLR/MINSK/PIZZERIA\r\n20.01.2020 15:08:55\r\n",
        to: [nil: "#{user.name}@co2offset.dev"]
      }

      {:ok, %{mail: mail, user: user}}
    end

    mocked_test "correctly renders telegram message", %{mail: mail, user: user} do
      MailgunProcessor.process(mail)

      transactions = Transactions.list_transactions()
      [transaction] = transactions

      assert("BY06ALFA30143400080030270000" = transaction.account)
      assert(Decimal.from_float(-18.26) == transaction.amount)
      assert(Decimal.from_float(450.56) == transaction.balance)
      assert("BYN" = transaction.currency_code)
      assert("BLR/MINSK/PIZZERIA" = transaction.to)
      assert(user.id == transaction.user_id)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       -18.26 BYN
       Категория
       Кому        BLR/MINSK/PIZZERIA
       Остаток     450.56
       Дата        #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")}

      ```
      """

      assert_called(
        Nadia.send_message(
          user.telegram_chat_id,
          expected_message,
          reply_markup: %Nadia.Model.InlineKeyboardMarkup{
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
          },
          parse_mode: "Markdown"
        )
      )
    end
  end

  describe "when mail is from unknown user" do
    setup do
      mail = %Receivex.Email{
        from: {"doesn't matter", "some.email@gmail.com"},
        html: "",
        sender: nil,
        subject: "adsd",
        text:
          "Карта 5.9737\r\nСо счёта: BY06ALFA30143400080030270000\r\nОплата товаров/услуг\r\nУспешно\r\nСумма:18.26 BYN\r\nОстаток:450.56 BYN\r\nНа время:15:08:56\r\nBLR/MINSK/PIZZERIA\r\n20.01.2020 15:08:55\r\n",
        to: [nil: "unknown@co2offset.dev"]
      }

      {:ok, %{mail: mail}}
    end

    test "do nothing", %{mail: mail} do
      MailgunProcessor.process(mail)

      transactions = Transactions.list_transactions()
      assert [] = transactions
    end
  end
end
