defmodule MarkevichMoney.Pipelines.AddTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  describe "/add message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
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
