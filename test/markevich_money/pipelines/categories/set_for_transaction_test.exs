defmodule MarkevichMoney.Pipelines.Categories.SetForTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Steps.Transaction.RenderTransaction

  describe "set_folder callback for folder with many categories" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      food_folder =
        insert(:transaction_category_folder, name: "Nested Food", has_single_category: false)

      category1 =
        insert(:transaction_category, name: "Food 1", transaction_category_folder: food_folder)

      category2 =
        insert(:transaction_category, name: "Food 2", transaction_category_folder: food_folder)

      single_category = insert(:transaction_category, name: "Single Home")

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => @set_category_or_folder_callback,
          "f_id" => food_folder.id
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
         single_category: single_category,
         category1: category1,
         category2: category2,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }}
    end

    mocked_test "Renders categories for the selected folder", context do
      reply_payload = Pipelines.call(context.callback_data)

      transaction = reply_payload[:transaction]
      assert(transaction.id == context.transaction.id)
      assert(transaction.transaction_category_id == nil)
      assert(Map.has_key?(reply_payload, :reply_markup))

      assert(
        reply_payload.reply_markup == %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"c_id\":#{context.category1.id},\"id\":#{context.transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: context.category1.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"c_id\":#{context.category2.id},\"id\":#{context.transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: context.category2.name,
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{context.transaction.id},\"mode\":\"ccfm\",\"pipeline\":\"#{@choose_category_folder_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "⬅️ Назад к категориям",
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

  describe "set_folder callback for folder with single category" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)
      insert(:transaction_category, name: "Food")
      category = insert(:transaction_category, name: "Home")
      folder = category.transaction_category_folder

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => @set_category_or_folder_callback,
          "f_id" => folder.id
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
         chosen_folder: folder,
         chosen_category: category,
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

    mocked_test "uses the only one category from the folder, sets the transaction category, fire event",
                context do
      reply_payload = Pipelines.call(context.callback_data)

      transaction = reply_payload[:transaction]
      assert(transaction.id == context.transaction.id)
      assert(transaction.transaction_category_id == context.chosen_category.id)

      assert_called(RenderTransaction.call(_))
      assert(Map.has_key?(reply_payload, :output_message))
      assert(reply_payload.output_message =~ context.chosen_category.name)

      assert(
        reply_payload[:reply_markup] == %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"mode\":\"#{@choose_category_folder_short_mode}\",\"pipeline\":\"#{@choose_category_folder_callback}\"}",
                switch_inline_query: nil,
                text: "📂 Выбрать категорию",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"action\":\"#{@transaction_set_ignored_status_callback}\",\"id\":#{transaction.id},\"pipeline\":\"#{@update_transaction_status_pipeline}\"}",
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

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_updated_event,
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end

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
          "pipeline" => @set_category_or_folder_callback,
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

    defmock MarkevichMoney.Steps.Transaction.RenderTransaction do
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
      assert(reply_payload.output_message =~ context.chosen_category.name)

      assert(
        reply_payload[:reply_markup] == %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"mode\":\"#{@choose_category_folder_short_mode}\",\"pipeline\":\"#{@choose_category_folder_callback}\"}",
                switch_inline_query: nil,
                text: "📂 Выбрать категорию",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"action\":\"#{@transaction_set_ignored_status_callback}\",\"id\":#{transaction.id},\"pipeline\":\"#{@update_transaction_status_pipeline}\"}",
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

      assert_enqueued(
        worker: MarkevichMoney.Gamification.Events.Broadcaster,
        args: %{
          event: @transaction_updated_event,
          transaction_id: transaction.id,
          user_id: context.user.id
        }
      )
    end
  end
end
