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
    UpdateTransaction
  }

  defmodule Template do
    require EEx

    @template """
      `<%= transaction.datetime %>`

      Оплата

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
    |> ParseDateTime.call()
    |> UpdateTransaction.call()
    # |> Map.put(:output_message, Template.render(payload))
    |> insert_rendered_template()
    |> SendMessage.call()
  end

  def insert_rendered_template(payload) do
    payload
    |> Map.put(:output_message, Template.render(payload[:transaction]))
  end
end
