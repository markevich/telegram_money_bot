defmodule MarkevichMoney.Pipelines.DeleteTransactionTest do
  @moduledoc false
  use MarkevichMoney.DataCase, async: true
  use MecksUnit.Case
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Pipelines
  alias MarkevichMoney.Transactions.Transaction

  describe "delete_transaction with 'dlt' action callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => "dlt_trn",
          "action" => "dlt"
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
    end

    mocked_test "deletes the transaction", context do
      transaction = context.transaction
      Pipelines.call(context.callback_data)

      query = from t in Transaction, where: t.id == ^transaction.id
      refute(Repo.exists?(query))

      assert_called(
        Nadia.edit_message_text(
          context.user.telegram_chat_id,
          context.message_id,
          "",
          "Удалено",
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "delete_transaction with 'ask' action callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => "dlt_trn",
          "action" => "ask"
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
    end

    mocked_test "render confirmation buttons", context do
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

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"dlt\",\"id\":#{context.transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "❌ Удалить ❌",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"cnl\",\"id\":#{context.transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Отмена",
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
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end

  describe "delete_transaction with 'cnl' action callback" do
    setup do
      user = insert(:user)
      transaction = insert(:transaction)

      message_id = 123
      callback_id = 234

      callback_data = %CallbackData{
        callback_data: %{
          "id" => transaction.id,
          "pipeline" => "dlt_trn",
          "action" => "cnl"
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

    defmock Nadia do
      def send_message(_chat_id, _message, _opts) do
      end

      def edit_message_text(_chat_id, _message_id, _, _message_text, _options) do
      end

      def answer_callback_query(_callback_id, _options) do
      end
    end

    mocked_test "cancel deletion and render transaction", context do
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

      expected_reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"id\":#{context.transaction.id},\"pipeline\":\"choose_category\"}",
              switch_inline_query: nil,
              text: "Категория",
              url: nil
            },
            %Nadia.Model.InlineKeyboardButton{
              callback_data:
                "{\"action\":\"ask\",\"id\":#{context.transaction.id},\"pipeline\":\"dlt_trn\"}",
              switch_inline_query: nil,
              text: "Удалить",
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
          reply_markup: expected_reply_markup,
          parse_mode: "Markdown"
        )
      )

      assert_called(Nadia.answer_callback_query(context.callback_id, text: "Success"))
    end
  end
end
