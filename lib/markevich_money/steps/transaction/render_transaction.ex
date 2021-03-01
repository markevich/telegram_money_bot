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
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    type = human_type(transaction_type)

    """
    Транзакция №#{transaction.id}(#{type})
    ```

    #{table}
    ```
    """
  end

  defp human_type(transaction_type) do
    case transaction_type do
      @transaction_type_income -> "Поступление"
      @transaction_type_expense -> "Списание"
      @transaction_type_unknown -> "Сомнительная"
    end
  end

  defp table_data(transaction, transaction_type) do
    list = []
    list = [["Сумма", amount(transaction)] | list]
    list = maybe_prepend_category(list, transaction, transaction_type)
    list = maybe_prepend_custom_description(list, transaction)
    list = [["Кому", transaction.to] | list]
    list = maybe_prepend_balance(list, transaction)
    list = [["Дата", Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")] | list]

    Enum.reverse(list)
  end

  defp maybe_prepend_category(list, transaction, transaction_type) do
    if transaction_type == @transaction_type_expense do
      [["Категория", category_name(transaction)] | list]
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

  defp category_name(transaction) do
    if transaction.transaction_category_id, do: transaction.transaction_category.name
  end

  defp amount(transaction) do
    amount_before_conversion =
      if transaction.external_amount do
        "(#{transaction.external_amount} #{transaction.external_currency})"
      end

    "#{transaction.amount} #{transaction.currency_code} #{amount_before_conversion}"
  end

  defp render_buttons(%Transaction{} = transaction) do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Категория",
            callback_data:
              Jason.encode!(%{pipeline: @choose_category_callback, id: transaction.id})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "Удалить",
            callback_data:
              Jason.encode!(%{
                pipeline: @delete_transaction_callback,
                action: @delete_transaction_callback_prompt,
                id: transaction.id
              })
          }
        ]
      ]
    }
  end
end
