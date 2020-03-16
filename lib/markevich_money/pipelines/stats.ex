defmodule MarkevichMoney.Pipelines.Stats do
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage, UpdateMessage}
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.{CallbackData, MessageData}

  def call(%CallbackData{callback_data: %{"type" => "c_week"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> put_current_week_dates()
    |> call()
  end

  def call(%CallbackData{callback_data: %{"type" => "c_month"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> put_current_month_dates()
    |> call()
  end

  def call(%CallbackData{callback_data: %{"type" => "p_month"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> put_previous_month_dates()
    |> call()
  end

  def call(%CallbackData{callback_data: %{"type" => "all"}} = callback_data) do
    callback_data
    |> Map.from_struct()
    |> put_all_time_dates()
    |> call()
  end

  def call(
        %{
          callback_data: %{"c_id" => category_id},
          stat_from: stat_from,
          stat_to: stat_to,
          current_user: current_user
        } = payload
      ) do
    payload
    |> Map.put(
      :output_message,
      render_category_table(current_user, stat_from, stat_to, category_id)
    )
    |> SendMessage.call()
    |> AnswerCallback.call()
  end

  def call(%{stat_from: stat_from, stat_to: stat_to, current_user: current_user} = payload) do
    payload
    |> render_all_categories_table(current_user, stat_from, stat_to)
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
            text: "Прошлый месяц",
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

  defp put_current_week_dates(data) do
    data
    |> Map.put(:stat_from, Timex.shift(Timex.now(), days: -7))
    |> Map.put(:stat_to, Timex.shift(Timex.now(), days: 1))
  end

  defp put_current_month_dates(data) do
    data
    |> Map.put(:stat_from, Timex.beginning_of_month(Timex.now()))
    |> Map.put(:stat_to, Timex.end_of_month(Timex.now()))
  end

  defp put_previous_month_dates(data) do
    previous_month = Timex.shift(Timex.now(), months: -1)

    data
    |> Map.put(:stat_from, Timex.beginning_of_month(previous_month))
    |> Map.put(:stat_to, Timex.end_of_month(previous_month))
  end

  defp put_all_time_dates(data) do
    data
    |> Map.put(:stat_from, Timex.parse!("2000-01-01T00:00:00+0000", "{ISO:Extended}"))
    |> Map.put(:stat_to, Timex.shift(Timex.now(), days: 1))
  end

  # credo:disable-for-next-line
  defp render_all_categories_table(payload, current_user, stat_from, stat_to) do
    transactions = Transactions.stats(current_user, stat_from, stat_to)

    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    if Enum.empty?(transactions) do
      message = "Отсутствуют транзакции за период с #{from} по #{to}."

      Map.put(payload, :output_message, message)
    else
      total =
        transactions
        |> Enum.reduce(0, fn {amount, _category_name, _category_id}, acc ->
          acc + Decimal.to_float(amount)
        end)
        |> abs()
        |> Float.ceil(2)

      header = ["Всего:", total]

      table =
        transactions
        |> Enum.map(fn {amount, category_name, _category_id} ->
          number = amount |> Decimal.to_float() |> abs() |> Float.ceil(2)
          [category_name, number]
        end)
        |> TableRex.Table.new(header)
        |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

      result_table = """
      Расходы c `#{from}` по `#{to}`:
      ```

      #{table}
      ```
      Детализированная статистика 👇👇
      """

      keyboard =
        transactions
        |> Enum.map(fn {_, category_name, category_id} ->
          %Nadia.Model.InlineKeyboardButton{
            text: category_name,
            callback_data:
              Jason.encode!(%{
                pipeline: "stats",
                type: payload.callback_data["type"],
                c_id: category_id
              })
          }
        end)
        |> Enum.chunk_every(2)

      if payload.callback_data["type"] == "all" do
        payload
        |> Map.put(:output_message, result_table)
      else
        reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: keyboard}

        payload
        |> Map.put(:output_message, result_table)
        |> Map.put(:reply_markup, reply_markup)
      end
    end
  end

  # credo:disable-for-next-line
  defp render_category_table(current_user, stat_from, stat_to, category_id) do
    transactions = Transactions.stats(current_user, stat_from, stat_to, category_id)
    category = Transactions.get_category!(category_id)

    from = Timex.format!(stat_from, "{0D}.{0M}.{YYYY}")
    to = Timex.format!(stat_to, "{0D}.{0M}.{YYYY}")

    if Enum.empty?(transactions) do
      "Отсутствуют транзакции за период с #{from} по #{to}."
    else
      total =
        transactions
        |> Enum.reduce(0, fn {_to, amount, _datetime}, acc ->
          acc + Decimal.to_float(amount)
        end)
        |> abs()
        |> Float.ceil(2)

      table =
        transactions
        |> Enum.map(fn {to, amount, datetime} ->
          number = amount |> Decimal.to_float() |> abs() |> Float.ceil(2)
          datetime = Timex.format!(datetime, "{0D}.{0M} {h24}:{m}")
          [number, to, datetime]
        end)
        |> TableRex.Table.new()
        |> TableRex.Table.put_column_meta(:all, align: :left, padding: 1)
        |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

      result = """
      Расходы "#{category.name}" c `#{from}` по `#{to}`:
      ```
        Всего: #{total}

      #{table}
      ```
      """

      result
    end
  end
end
