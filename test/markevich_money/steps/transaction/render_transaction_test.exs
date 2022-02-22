defmodule MarkevichMoney.Steps.Transaction.RenderTransactionTest do
  @moduledoc false
  use MarkevichMoney.Constants
  use MarkevichMoney.DataCase, async: true
  alias MarkevichMoney.Steps.Transaction.RenderTransaction

  describe "happy path" do
    setup do
      {:ok, %{transaction: insert(:transaction, status: @transaction_status_normal)}}
    end

    test "set required payload keys", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert(Map.has_key?(reply_payload, :output_message))
      assert(Map.has_key?(reply_payload, :reply_markup))
    end
  end

  describe "render buttons markup" do
    setup do
      {:ok, %{transaction: insert(:transaction, status: @transaction_status_normal)}}
    end

    test "returns buttons struct", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

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
    end
  end

  describe "transaction (outcome)" do
    setup do
      {:ok, %{transaction: insert(:transaction, status: @transaction_status_normal)}}
    end

    test "renders transaction", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➖ Транзакция №#{transaction.id}(Списание)
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "transaction (income)" do
    setup do
      {:ok, %{transaction: insert(:transaction, amount: 10, status: @transaction_status_normal)}}
    end

    test "renders transaction", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➕ Транзакция №#{transaction.id}(Поступление)
             ```

             Сумма    #{transaction.amount} #{transaction.currency_code}
             Кому     #{transaction.to}
             Остаток  #{transaction.balance}
             Дата     #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "transaction (zero)" do
    setup do
      {:ok, %{transaction: insert(:transaction, amount: 0, status: @transaction_status_normal)}}
    end

    test "renders transaction", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             🛸 Транзакция №#{transaction.id}(Сомнительная)
             ```

             Сумма    #{transaction.amount} #{transaction.currency_code}
             Кому     #{transaction.to}
             Остаток  #{transaction.balance}
             Дата     #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "transaction with category" do
    setup do
      category = insert(:transaction_category)

      transaction =
        insert(:transaction, transaction_category: category, status: @transaction_status_normal)

      {:ok, %{transaction: transaction, category: category}}
    end

    test "renders transaction", %{transaction: transaction, category: category} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➖ Транзакция №#{transaction.id}(Списание)
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория  #{category.name}
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "transaction with external amount" do
    setup do
      {:ok,
       %{
         transaction:
           insert(:transaction,
             external_amount: 10,
             external_currency: "USD",
             status: @transaction_status_normal
           )
       }}
    end

    test "renders transaction", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➖ Транзакция №#{transaction.id}(Списание)
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code} (#{transaction.external_amount} #{transaction.external_currency})
             Категория
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "manual transaction" do
    setup do
      {:ok,
       %{
         transaction:
           insert(:transaction,
             external_amount: 10,
             external_currency: "USD",
             account: @manual_account,
             status: @transaction_status_normal
           )
       }}
    end

    test "renders transaction", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➖ Транзакция №#{transaction.id}(Списание)
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code} (#{transaction.external_amount} #{transaction.external_currency})
             Категория
             Кому       #{transaction.to}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "transaction with custom description" do
    setup do
      {:ok,
       %{
         transaction:
           insert(:transaction, custom_description: "Big Mac", status: @transaction_status_normal)
       }}
    end

    test "renders transaction", %{transaction: transaction} do
      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➖ Транзакция №#{transaction.id}(Списание)
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория
             Описание   #{transaction.custom_description}
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "transaction with category with folder" do
    setup do
      folder =
        insert(:transaction_category_folder, name: "RenderFood", has_single_category: false)

      category =
        insert(:transaction_category, name: "Fast Food", transaction_category_folder: folder)

      transaction =
        insert(:transaction, transaction_category: category, status: @transaction_status_normal)

      {
        :ok,
        %{transaction: transaction, category: category, folder: folder}
      }
    end

    test "renders transaction", context do
      transaction = context.transaction
      category = context.category
      folder = context.folder

      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ➖ Транзакция №#{transaction.id}(Списание)
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория  #{folder.name}/        \n           #{category.name}
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end
  end

  describe "Requires confirmation transaction" do
    setup do
      transaction = insert(:transaction, status: @transaction_status_requires_confirmation)

      {
        :ok,
        %{transaction: transaction}
      }
    end

    test "renders transaction", context do
      transaction = context.transaction

      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ⚠️ Транзакция №#{transaction.id}(Списание)
             _Ожидает подтверждения_
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end

    test "renders valid buttons", context do
      transaction = context.transaction

      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert(
        reply_payload[:reply_markup] == %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"action\":\"#{@transaction_set_normal_status_callback}\",\"id\":#{transaction.id},\"pipeline\":\"#{@update_transaction_status_pipeline}\"}",
                switch_inline_query: nil,
                text: "✅ Учитывать в статистике",
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
    end
  end

  describe "Bank freeze confirmation transaction" do
    setup do
      transaction = insert(:transaction, status: @transaction_status_bank_fund_freeze)

      {
        :ok,
        %{transaction: transaction}
      }
    end

    test "renders transaction", context do
      transaction = context.transaction

      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             ⏳ Транзакция №#{transaction.id}(Блокировка средств)
             _Не учитывается_
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end

    test "renders valid buttons", context do
      transaction = context.transaction

      reply_payload = RenderTransaction.call(%{transaction: transaction})

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
            ]
          ]
        }
      )
    end
  end

  describe "ignored transaction" do
    setup do
      transaction = insert(:transaction, status: @transaction_status_ignored)

      {
        :ok,
        %{transaction: transaction}
      }
    end

    test "renders transaction", context do
      transaction = context.transaction

      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert reply_payload[:output_message] == """
             🗑️ Транзакция №#{transaction.id}(Списание)
             _Не учитывается_
             ```

             Сумма      #{transaction.amount} #{transaction.currency_code}
             Категория
             Кому       #{transaction.to}
             Остаток    #{transaction.balance}
             Дата       #{Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")}

             ```
             """
    end

    test "renders valid buttons", context do
      transaction = context.transaction

      reply_payload = RenderTransaction.call(%{transaction: transaction})

      assert(
        reply_payload[:reply_markup] == %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %Nadia.Model.InlineKeyboardButton{
                callback_data:
                  "{\"action\":\"#{@transaction_set_normal_status_callback}\",\"id\":#{transaction.id},\"pipeline\":\"#{@update_transaction_status_pipeline}\"}",
                switch_inline_query: nil,
                text: "↩️ Учитывать в статистике",
                url: nil
              }
            ]
          ]
        }
      )
    end
  end
end
