defmodule MarkevichMoney.Pipelines.RerenderTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Steps.Transaction.RenderTransaction

  describe "call" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => @rerender_transaction_callback
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

    mocked_test "rerenders transaction", context do
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
                  "{\"id\":#{context.transaction.id},\"mode\":\"#{@choose_category_folder_short_mode}\",\"pipeline\":\"#{@choose_category_folder_callback}\"}",
                switch_inline_query: nil,
                text: "📂 Выбрать категорию",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"action\":\"#{@transaction_set_ignored_status_callback}\",\"id\":#{context.transaction.id},\"pipeline\":\"#{@update_transaction_status_pipeline}\"}",
                switch_inline_query: nil,
                text: "🗑 Не учитывать в статистике",
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

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Успешно"))
    end
  end
end
