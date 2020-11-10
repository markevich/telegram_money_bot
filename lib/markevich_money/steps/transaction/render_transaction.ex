defmodule MarkevichMoney.Steps.Transaction.RenderTransaction do
  use Timex
  use MarkevichMoney.Constants
  use MarkevichMoney.Constants
  alias MarkevichMoney.Transactions.Transaction

  def call(%{transaction: transaction} = payload) do
    payload
    |> Map.put(:output_message, render_message(transaction))
    |> Map.put(:reply_markup, render_buttons(transaction))
  end

  defp render_message(%Transaction{} = transaction) do
    category = if transaction.transaction_category_id, do: transaction.transaction_category.name

    amount_before_conversion =
      if transaction.external_amount do
        "(#{transaction.external_amount} #{transaction.external_currency})"
      end

    table =
      [
        [
          "Сумма",
          "#{transaction.amount} #{transaction.currency_code} #{amount_before_conversion}"
        ],
        ["Категория", category],
        ["Кому", transaction.to],
        ["Остаток", transaction.balance],
        # ["Счет", transaction.account],
        ["Дата", Timex.format!(transaction.issued_at, "{0D}.{0M}.{YY} {h24}:{0m}")]
      ]
      |> TableRex.Table.new([], "")
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

    type =
      case Decimal.compare(transaction.amount, 0) do
        :gt -> "Поступление"
        :lt -> "Списание"
        :eq -> "Сомнительная"
      end

    """
    Транзакция №#{transaction.id}(#{type})
    ```

    #{table}
    ```
    """
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
