defmodule TelegramMoneyBot.Pipelines.Categories.SetForTransactionTest do
  @moduledoc false
  use TelegramMoneyBot.DataCase, async: true
  use TelegramMoneyBot.MockNadia, async: true
  use TelegramMoneyBot.Constants
  use Oban.Testing, repo: TelegramMoneyBot.Repo
  alias TelegramMoneyBot.CallbackData
  alias TelegramMoneyBot.Pipelines
  alias TelegramMoneyBot.Steps.Transaction.RenderTransaction

  describe "set_category callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)
      insert(:transaction_category, name: "Food")
      category = insert(:transaction_category, name: "Home")

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => @set_category_callback,
          "c_id" => category.id
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
         chosen_category: category,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    defmock TelegramMoneyBot.Steps.Transaction.RenderTransaction do
      def call(_) do
        :passthrough
      end
    end

    mocked_test "sets the transaction category, fire event", context do
      reply_payload = Pipelines.call(context.callback_data)

      transaction = reply_payload[:transaction]
      assert(transaction.id == context.transaction.id)
      assert(transaction.transaction_category_id == context.chosen_category.id)

      assert_called(RenderTransaction.call(_))
      assert(Map.has_key?(reply_payload, :output_message))

      assert(
        reply_payload[:reply_markup] == %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"pipeline\":\"#{@choose_category_callback}\"}",
                switch_inline_query: nil,
                text: "Категория",
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"action\":\"#{@delete_transaction_callback_prompt}\",\"id\":#{transaction.id},\"pipeline\":\"#{
                    @delete_transaction_callback
                  }\"}",
                switch_inline_query: nil,
                text: "Удалить",
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

      assert_enqueued(
        worker: TelegramMoneyBot.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_updated_event,
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end
end
