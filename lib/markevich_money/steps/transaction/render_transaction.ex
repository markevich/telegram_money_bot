defmodule MarkevichMoney.Steps.Transaction.RenderTransaction do
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

      | На сумму`  |` `<%= transaction.amount %>` <%= transaction.currency_code %>
      <%= if transaction.transaction_category do %>
      | Категория:` |` `<%= transaction.transaction_category.name %>`
      <% end %>
      | Кому:`     |` <%= transaction.target %>
      | Счет:`     |` <%= transaction.account %>
      | Остаток`   |` <%= transaction.balance %>

      %meta{id: <%= transaction.id %>}
    """

    EEx.function_from_string(:def, :render, @template, [:transaction])
  end

  def call(%{transaction: transaction} = payload) do
    payload
    |> Map.put(:output_message, Template.render(transaction))
    |> insert_buttons()
  end

  def insert_buttons(%{transaction: %{id: transaction_id}} = payload) do
    callback_data = Jason.encode!(%{pipeline: "choose_category", id: transaction_id})

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
