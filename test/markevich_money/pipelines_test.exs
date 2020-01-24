defmodule MarkevichMoney.PipelinesTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.MessageData

  defmock Nadia, preserve: true do
    def send_message(_chat_id, _message, _opts) do
    end

    def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
    end

    def answer_callback_query(_callback_id, _options) do
    end
  end

  describe "when unauthorized message data" do
    mocked_test "renders unauthorized message" do
      Pipelines.call(%MessageData{chat_id: -1, current_user: nil})

      assert_called(Nadia.send_message(-1, "Unauthorized", parse_mode: "Markdown"))
    end
  end

  describe "choose_category callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)
      category1 = insert(:transaction_category)
      category2 = insert(:transaction_category)

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

    mocked_test "sets the transaction category", context do
      transaction = context.transaction
      Pipelines.call(context.callback_data)

      expected_message = """
      Транзакция №#{transaction.id}(Списание)
      ```

       Сумма       #{transaction.amount} #{transaction.currency_code}
       Категория
       Кому        #{transaction.target}
       Остаток     #{transaction.balance}
       Дата        #{Timex.format!(transaction.datetime, "{0D}.{0M}.{YY} {h24}:{0m}")}

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
end
