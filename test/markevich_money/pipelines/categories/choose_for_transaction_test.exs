defmodule MarkevichMoney.Pipelines.Categories.ChooseForTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Steps.Transaction.RenderTransaction

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

    defmock MarkevichMoney.Steps.Transaction.RenderTransaction do
      def call(_) do
        :passthrough
      end
    end

    mocked_test "renders categories to choose from", context do
      reply_payload = Pipelines.call(context.callback_data)

      transaction = reply_payload[:transaction]
      assert(transaction.id == context.transaction.id)

      assert_called(RenderTransaction.call(_))
      assert(Map.has_key?(reply_payload, :output_message))

      assert(
        reply_payload[:reply_markup] == %Nadia.Model.InlineKeyboardMarkup{
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
      )

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          "",
          _,
          reply_markup: reply_payload[:reply_markup],
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end
end
