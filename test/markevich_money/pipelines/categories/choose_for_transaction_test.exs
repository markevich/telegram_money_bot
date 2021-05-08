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

    # ordering
    insert_list(2, :transaction, user: user, transaction_category: category2)
    insert_list(1, :transaction, user: user, transaction_category: category1)

    message_id = 123
    callback_id = 234

    callback_data = %CallbackData{
      callback_data: %{"id" => transaction.id, "pipeline" => @choose_category_callback},
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

  describe "choose_category callback without mode(backward compatibility mode)" do
    setup [:setup_default_env]

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
                  "{\"c_id\":#{context.category2.id},\"id\":#{transaction.id},\"pipeline\":\"#{
                    @set_category_callback
                  }\"}",
                switch_inline_query: nil,
                text: context.category2.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"c_id\":#{context.category1.id},\"id\":#{transaction.id},\"pipeline\":\"#{
                    @set_category_callback
                  }\"}",
                switch_inline_query: nil,
                text: context.category1.name,
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"mode\":\"#{@choose_category_full_mode}\",\"pipeline\":\"#{
                    @choose_category_callback
                  }\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "☰ Показать больше категорий️",
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

  describe "choose_category callback with short list mode" do
    def set_short_mode(context) do
      callback_data = %CallbackData{
        callback_data: %{
          "id" => context.transaction.id,
          "mode" => @choose_category_short_mode,
          "pipeline" => @choose_category_callback
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
                  "{\"c_id\":#{context.category2.id},\"id\":#{transaction.id},\"pipeline\":\"#{
                    @set_category_callback
                  }\"}",
                switch_inline_query: nil,
                text: context.category2.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"c_id\":#{context.category1.id},\"id\":#{transaction.id},\"pipeline\":\"#{
                    @set_category_callback
                  }\"}",
                switch_inline_query: nil,
                text: context.category1.name,
                url: nil
              }
            ],
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"id\":#{transaction.id},\"mode\":\"#{@choose_category_full_mode}\",\"pipeline\":\"#{
                    @choose_category_callback
                  }\"}",
                switch_inline_query: nil,
                switch_inline_query_current_chat: nil,
                text: "☰ Показать больше категорий️",
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

  describe "choose_category callback with full list mode" do
    def set_full_mode(context) do
      callback_data = %CallbackData{
        callback_data: %{
          "id" => context.transaction.id,
          "mode" => @choose_category_full_mode,
          "pipeline" => @choose_category_callback
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
                  "{\"c_id\":#{context.category2.id},\"id\":#{transaction.id},\"pipeline\":\"#{
                    @set_category_callback
                  }\"}",
                switch_inline_query: nil,
                text: context.category2.name,
                url: nil
              },
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"c_id\":#{context.category1.id},\"id\":#{transaction.id},\"pipeline\":\"#{
                    @set_category_callback
                  }\"}",
                switch_inline_query: nil,
                text: context.category1.name,
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
