defmodule MarkevichMoney.Pipelines.Categories.ChooseForTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Steps.Transaction.RenderTransaction

  def setup_default_env(context) do
    user = insert(:user)
    transaction = insert(:transaction, user: user)
    category1 = insert(:transaction_category, name: "choose 1")
    category2 = insert(:transaction_category, name: "choose 2")

    folder1 = category1.transaction_category_folder
    folder2 = category2.transaction_category_folder
    folder_with_many_categories = insert(:transaction_category_folder, has_single_category: false)

    category_for_big_folder1 =
      insert(:transaction_category,
        name: "choose big 1",
        transaction_category_folder: folder_with_many_categories
      )

    category_for_big_folder2 =
      insert(:transaction_category,
        name: "choose big 2",
        transaction_category_folder: folder_with_many_categories
      )

    # ordering
    insert_list(3, :transaction, user: user, transaction_category: category2)
    insert_list(2, :transaction, user: user, transaction_category: category1)
    insert_list(1, :transaction, user: user, transaction_category: category_for_big_folder1)
    insert_list(1, :transaction, user: user, transaction_category: category_for_big_folder2)

    message_id = 123
    callback_id = 234

    callback_data = %CallbackData{
      callback_data: %{"id" => transaction.id, "pipeline" => @choose_category_folder_callback},
      callback_id: callback_id,
      chat_id: user.telegram_chat_id,
      current_user: user,
      message_id: message_id,
      message_text: "doesn't matter"
    }

    {:ok,
     Map.merge(
       context,
       %{
         user: user,
         callback_data: callback_data,
         category1: category1,
         category2: category2,
         folder1: folder1,
         folder2: folder2,
         folder_with_many_categories: folder_with_many_categories,
         transaction: transaction,
         message_id: message_id,
         callback_id: callback_id
       }
     )}
  end

  defmock MarkevichMoney.Steps.Transaction.RenderTransaction, preserve: true do
    def call(_) do
      :passthrough
    end
  end

  describe "choose_category_folder callback without mode(backward compatibility mode)" do
    setup [:setup_default_env]

    mocked_test "renders folders/categories to choose from", context do
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
                  "{\"f_id\":#{context.folder2.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: context.folder2.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"f_id\":#{context.folder1.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: context.folder1.name,
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"f_id\":#{context.folder_with_many_categories.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: "#{context.folder_with_many_categories.name}/",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"mode\":\"#{@choose_category_folder_full_mode}\",\"pipeline\":\"#{@choose_category_folder_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "☰ Показать больше категорий️",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"pipeline\":\"#{@rerender_transaction_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "❌ Отмена",
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

  describe "choose_folder callback with short list mode" do
    def set_short_mode(context) do
      callback_data = %CallbackData{
        callback_data: %{
          "id" => context.transaction.id,
          "mode" => @choose_category_folder_short_mode,
          "pipeline" => @choose_category_folder_callback
        },
        callback_id: context.callback_id,
        chat_id: context.user.telegram_chat_id,
        current_user: context.user,
        message_id: context.message_id,
        message_text: "doesn't matter"
      }

      {
        :ok,
        Map.merge(context, %{
          callback_data: callback_data
        })
      }
    end

    setup [:setup_default_env, :set_short_mode]

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
                  "{\"f_id\":#{context.folder2.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: context.folder2.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"f_id\":#{context.folder1.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: context.folder1.name,
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"f_id\":#{context.folder_with_many_categories.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: "#{context.folder_with_many_categories.name}/",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"mode\":\"#{@choose_category_folder_full_mode}\",\"pipeline\":\"#{@choose_category_folder_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "☰ Показать больше категорий️",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"pipeline\":\"#{@rerender_transaction_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "❌ Отмена",
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

  describe "choose_folder callback with full list mode" do
    def set_full_mode(context) do
      callback_data = %CallbackData{
        callback_data: %{
          "id" => context.transaction.id,
          "mode" => @choose_category_folder_full_mode,
          "pipeline" => @choose_category_folder_callback
        },
        callback_id: context.callback_id,
        chat_id: context.user.telegram_chat_id,
        current_user: context.user,
        message_id: context.message_id,
        message_text: "doesn't matter"
      }

      {
        :ok,
        Map.merge(context, %{
          callback_data: callback_data
        })
      }
    end

    setup [:setup_default_env, :set_full_mode]

    mocked_test "renders folders to choose from", context do
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
                  "{\"f_id\":#{context.folder2.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: context.folder2.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"f_id\":#{context.folder1.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: context.folder1.name,
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"f_id\":#{context.folder_with_many_categories.id},\"id\":#{transaction.id},\"pipeline\":\"#{@set_category_or_folder_callback}\"}",
                switch_inline_query: nil,
                text: "#{context.folder_with_many_categories.name}/",
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"pipeline\":\"#{@rerender_transaction_callback}\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "❌ Отмена",
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
