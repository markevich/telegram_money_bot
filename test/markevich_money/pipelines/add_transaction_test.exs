defmodule MarkevichMoney.Pipelines.AddTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use Oban.Testing, repo: MarkevichMoney.Repo
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  describe "/add message" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    mocked_test "insert and renders transaction, fire event", %{user: user} do
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

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{event: "transaction_created", transaction_id: transaction.id, user_id: user_id}
      )
    end
  end
end
