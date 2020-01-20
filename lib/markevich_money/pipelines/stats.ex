defmodule MarkevichMoney.Pipelines.Stats do
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, UpdateMessage, SendMessage}
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.{CallbackData, MessageData}

  def call(%CallbackData{callback_data: %{"type" => "c_week"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.shift(Timex.now(), days: -7))
    |> Map.put(:stat_to, Timex.now())
    |> call()
  end

  def call(%CallbackData{callback_data: %{"type" => "c_month"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.beginning_of_month(Timex.now()))
    |> Map.put(:stat_to, Timex.end_of_month(Timex.now()))
    |> call()
  end

  def call(%CallbackData{callback_data: %{"type" => "p_month"}} = callback_data) do
    previous_month = Timex.shift(Timex.now(), months: -1)

    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.beginning_of_month(previous_month))
    |> Map.put(:stat_to, Timex.end_of_month(previous_month))
    |> call()
  end

  def call(%CallbackData{callback_data: %{"type" => "all"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> Map.put(:stat_from, Timex.parse!("2000-01-01T00:00:00+0000", "{ISO:Extended}"))
    |> Map.put(:stat_to, Timex.now())
    |> call()
  end

  def call(%{stat_from: stat_from, stat_to: stat_to, current_user: current_user} = payload) do
    payload
    |> Map.put(:output_message, render_table(current_user, stat_from, stat_to))
    |> UpdateMessage.call()
    |> AnswerCallback.call()
  end

  def call(%MessageData{} = payload) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Текущая неделя",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :c_week})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "Текущий месяц",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :c_month})
          }
        ],
        [
          %Nadia.Model.InlineKeyboardButton{
            text: "Предыдущий месяц",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :p_month})
          },
          %Nadia.Model.InlineKeyboardButton{
            text: "За все время",
            callback_data: Jason.encode!(%{pipeline: :stats, type: :all})
          }
        ]
      ]
    }

    payload
    |> Map.put(:output_message, "Выберите тип")
    |> Map.put(:reply_markup, reply_markup)
    |> SendMessage.call()
  end

  defp render_table(current_user, stat_from, stat_to) do
    transactions = Transactions.stats(current_user, stat_from, stat_to)

    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    if Enum.empty?(transactions) do
      "Отсутствуют транзакции за период с #{from} по #{to}."
    else
      table =
        transactions
        |> Enum.map(fn {amount, category_name} -> [amount, category_name] end)
        |> TableRex.Table.new()
        |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

      """
      Расходы c `#{from}` по `#{to}`:
      ```

      #{table}
      ```
      """
    end
  end
end
