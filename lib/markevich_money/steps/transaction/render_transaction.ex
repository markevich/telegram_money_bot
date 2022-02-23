defmodule MarkevichMoney.Steps.Transaction.RenderTransaction do
  use Timex
  use MarkevichMoney.Constants

  alias MarkevichMoney.Transactions.Transaction

  def call(%{transaction: transaction} = payload) do
    transaction_type = Transaction.type(transaction)

    payload =
      payload
      |> Map.put(:output_message, render_message(transaction, transaction_type))

    if transaction_type == @transaction_type_expense do
      Map.put(payload, :reply_markup, render_buttons(transaction))
    else
      payload
    end
  end

  defp render_message(%Transaction{} = transaction, transaction_type) do
    table =
      transaction
      |> table_data(transaction_type)
      |> TableRex.Table.new([], "")
      |> TableRex.Table.put_column_meta(0, padding: 0)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    transaction_emoji = transaction_emoji(transaction_type, transaction.status)
    transaction_type = transaction_type(transaction_type, transaction.status)
    transaction_status = transaction_human_status(transaction.status)

    transaction_header =
      """
      #{transaction_emoji} Транзакция №#{transaction.id}(#{transaction_type})
      #{transaction_status}
      """
      |> String.trim()

    """
    #{transaction_header}
    ```

    #{table}
    ```
    """
  end

  defp transaction_emoji(transaction_type, transaction_status) do
    normal_type_emoji =
      case transaction_type do
        @transaction_type_income -> "➕"
        @transaction_type_expense -> "➖"
        @transaction_type_unknown -> "🛸"
      end

    case transaction_status do
      @transaction_status_normal -> normal_type_emoji
      @transaction_status_requires_confirmation -> "⚠️"
      @transaction_status_bank_fund_freeze -> "⏳"
      @transaction_status_ignored -> "🗑️"
    end
  end

  defp transaction_type(transaction_type, transaction_status) do
    case {transaction_type, transaction_status} do
      {_, @transaction_status_bank_fund_freeze} -> "Блокировка средств"
      {@transaction_type_income, _} -> "Поступление"
      {@transaction_type_expense, _} -> "Списание"
      {@transaction_type_unknown, _} -> "Сомнительная"
    end
  end

  defp transaction_human_status(transaction_status) do
    case transaction_status do
      @transaction_status_normal ->
        ""

      @transaction_status_requires_confirmation ->
        """
        _Ожидает подтверждения_
        _Не учитывается_
        """

      @transaction_status_bank_fund_freeze ->
        "_Не учитывается_"

      @transaction_status_ignored ->
        "_Не учитывается_"
    end
  end

  defp table_data(transaction, transaction_type) do
    list = []
    list = [["Сумма", amount(transaction)] | list]
    list = maybe_prepend_category(list, transaction, transaction_type)
    list = maybe_prepend_custom_description(list, transaction)
    list = [["Кому", transaction.to] | list]
    list = maybe_prepend_balance(list, transaction)

    list = [
      ["Дата", Timex.format!(transaction.issued_at, "{0D}.{0M}.{YYYY} в {h24}:{0m}")] | list
    ]

    Enum.reverse(list)
  end

  defp maybe_prepend_category(list, transaction, transaction_type) do
    if transaction_type == @transaction_type_expense do
      [["Категория", category_with_folder_names(transaction)] | list]
    else
      list
    end
  end

  defp maybe_prepend_custom_description(list, transaction) do
    if transaction.custom_description do
      [["Описание", transaction.custom_description] | list]
    else
      list
    end
  end

  defp maybe_prepend_balance(list, transaction) do
    if transaction.account == @manual_account do
      list
    else
      [["Остаток", transaction.balance] | list]
    end
  end

  defp category_with_folder_names(transaction) do
    if transaction.transaction_category_id do
      if transaction.transaction_category.transaction_category_folder.has_single_category do
        """
        #{transaction.transaction_category.name}
        """
      else
        """
        #{transaction.transaction_category.transaction_category_folder.name}/
        #{transaction.transaction_category.name}
        """
      end
    end
  end

  defp amount(transaction) do
    amount_before_conversion =
      if transaction.external_amount do
        "(#{transaction.external_amount} #{transaction.external_currency})"
      end

    "#{transaction.amount} #{transaction.currency_code} #{amount_before_conversion}"
  end

  defp render_buttons(%Transaction{status: @transaction_status_normal} = transaction) do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "📂 Выбрать категорию",
            callback_data:
              Jason.encode!(%{
                pipeline: @choose_category_folder_callback,
                id: transaction.id,
                mode: @choose_category_folder_short_mode
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "🗑 Не учитывать в статистике",
            callback_data:
              Jason.encode!(%{
                pipeline: @update_transaction_status_pipeline,
                action: @transaction_set_ignored_status_callback,
                id: transaction.id
              })
          }
        ]
      ]
    }
  end

  defp render_buttons(%Transaction{status: @transaction_status_ignored} = transaction) do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "↩️ Учитывать в статистике",
            callback_data:
              Jason.encode!(%{
                pipeline: @update_transaction_status_pipeline,
                action: @transaction_set_normal_status_callback,
                id: transaction.id
              })
          }
        ]
      ]
    }
  end

  defp render_buttons(
         %Transaction{status: @transaction_status_requires_confirmation} = transaction
       ) do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "✅ Учитывать в статистике",
            callback_data:
              Jason.encode!(%{
                pipeline: @update_transaction_status_pipeline,
                action: @transaction_set_normal_status_callback,
                id: transaction.id
              })
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "🗑 Не учитывать в статистике",
            callback_data:
              Jason.encode!(%{
                pipeline: @update_transaction_status_pipeline,
                action: @transaction_set_ignored_status_callback,
                id: transaction.id
              })
          }
        ]
      ]
    }
  end

  defp render_buttons(%Transaction{status: @transaction_status_bank_fund_freeze} = transaction) do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "📂 Выбрать категорию",
            callback_data:
              Jason.encode!(%{
                pipeline: @choose_category_folder_callback,
                id: transaction.id,
                mode: @choose_category_folder_short_mode
              })
          }
        ]
      ]
    }
  end
end
