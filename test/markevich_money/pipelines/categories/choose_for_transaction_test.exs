defmodule MarkevichMoney.Pipelines.Categories.ChooseForTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines

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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
        {:ok, nil}
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
        {:ok, nil}
      end

      def answer_callback_query(_callback_id, _options) do
        {:ok, nil}
      end
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
          "",
          expected_message,
          reply_markup: expected_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end
end
