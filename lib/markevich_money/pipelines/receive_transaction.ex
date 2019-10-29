defmodule MarkevichMoney.Pipelines.ReceiveTransaction do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  alias MarkevichMoney.Steps.Transaction.{
    CreateTransaction,
    ParseAccount,
    ParseAmount,
    ParseBalance,
    ParseCurrencyCode,
    ParseDateTime,
    ParseTarget,
    ParseType,
    PredictCategory,
    UpdateTransaction
  }

  defmodule Template do
    require EEx

    @template """
      `<%= transaction.datetime %>`

      <%=
        case transaction.type do
          "income" -> "Поступление"
          "outcome" -> "Списание"
          true -> "Неизвестно"
        end
      %>

      | На сумму` |` `<%= transaction.amount %>` <%= transaction.currency_code %>
      | Кому:`    |` `<%= transaction.target %>`

      | Счет:`    |` `<%= transaction.account %>`
      | Остаток`  |` `<%= transaction.balance %>` <%= transaction.currency_code %>

      %meta{id: <%= transaction.id %>}
    """

    EEx.function_from_string(:def, :render, @template, [:transaction])
  end

  def call(payload) do
    payload
    |> CreateTransaction.call()
    |> Map.put(:parsed_attributes, %{})
    |> ParseAccount.call()
    |> ParseAmount.call()
    |> ParseCurrencyCode.call()
    |> ParseBalance.call()
    |> ParseTarget.call()
    |> ParseType.call()
    |> ParseDateTime.call()
    |> UpdateTransaction.call()
    |> PredictCategory.call()
    |> insert_buttons()
    |> insert_rendered_template()
    |> SendMessage.call()
  end

  def insert_rendered_template(payload) do
    payload
    |> Map.put(:output_message, Template.render(payload[:transaction]))
  end

  def insert_buttons(%{transaction: %{id: transaction_id}} = payload) do
    callback_data = Jason.encode!(%{pipeline: "choose_category", id: transaction_id })
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Выбрать категорию",
            callback_data: callback_data
          }
        ]
      ]
    }

    payload
    |> Map.put(:reply_markup, reply_markup)
  end
end
