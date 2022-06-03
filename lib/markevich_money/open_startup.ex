defmodule MarkevichMoney.OpenStartup do
  import Ecto.Query, warn: false
  use MarkevichMoney.Constants

  alias MarkevichMoney.Repo

  alias MarkevichMoney.OpenStartup.Profit

  def list_profits do
    Repo.all(Profit)
  end

  def list_transactions_count_grouped_by_month do
    {:ok, %{rows: rows}} =
      Repo.query("""
      SELECT generated::date as gen_date, monthly_transactions.c from
      generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month') AS generated
      INNER JOIN LATERAL (
        SELECT count(t.id) as c
        FROM transactions t
        WHERE date_trunc('month', t.inserted_at)::date = date_trunc('month', generated::date)
      ) as monthly_transactions
      ON TRUE
      ORDER BY gen_date
      """)

    rows
    |> Enum.map(fn row ->
      [date, transactions_count] = row

      %{
        date: date,
        transactions_count: transactions_count
      }
    end)
  end

  def list_profits_grouped_by_month do
    query =
      from(profit in Profit,
        select: %{
          amount: sum(profit.amount),
          date: fragment("date_trunc('month', ?)::date as month", profit.date)
        },
        where: profit.date > fragment("CURRENT_DATE - INTERVAL '6 months'"),
        where: profit.amount > 5 or profit.amount < -5,
        group_by: fragment("month"),
        order_by: fragment("month")
      )

    Repo.all(query)
  end

  def list_incomes do
    from(p in Profit,
      where: p.amount > 5,
      where: p.date > fragment("CURRENT_DATE - INTERVAL '6 months'"),
      order_by: p.date
    )
    |> Repo.all()
  end

  def list_expenses do
    from(p in Profit,
      where: p.amount < -5,
      where: p.date > fragment("CURRENT_DATE - INTERVAL '6 months'"),
      order_by: p.date
    )
    |> Repo.all()
  end

  def list_popular_categories_by_month do
    {:ok, %{rows: rows}} =
      Repo.query("""
      SELECT generated::date as gen_date, category_name, records_count from
      generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month') AS generated
      INNER JOIN LATERAL (
        SELECT count(st0."amount") AS "records_count",
               date_trunc('month', st0."issued_at")::date AS "month",
               st1."name" AS "category_name"
        FROM "transactions" AS st0
        INNER JOIN "transaction_categories" AS st1 ON st1."id" = st0."transaction_category_id"
        WHERE (st0."amount" < 0)
        AND st0."status" = '#{@transaction_status_normal}'
        AND (date_trunc('month', st0."issued_at")::date = generated::date)
        AND (NOT (st0."transaction_category_id" IS NULL))
        GROUP BY month, st1."name"
        ORDER BY month, st0."count" DESC
        LIMIT 4) AS s1
      ON TRUE
      """)

    rows
    |> Enum.map(fn row ->
      [date, category_name, records_count] = row

      %{
        date: date,
        category_name: category_name,
        records_count: records_count
      }
    end)
    |> Enum.group_by(fn row ->
      row.category_name
    end)
    |> Enum.map(fn {category_name, category_rows} ->
      {
        category_name,
        Enum.reduce(category_rows, [], &group_by_near_months/2) |> Enum.reverse()
      }
    end)
    |> Enum.into(%{})
  end

  def list_most_expensive_categories_by_month do
    {:ok, %{rows: rows}} =
      Repo.query("""
      SELECT generated::date as gen_date, category_name, sum_amount from
      generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month') AS generated
      INNER JOIN LATERAL (
        SELECT sum(st0."amount") AS "sum_amount",
               date_trunc('month', st0."issued_at")::date AS "month",
               st1."name" AS "category_name"
        FROM "transactions" AS st0
        INNER JOIN "transaction_categories" AS st1 ON st1."id" = st0."transaction_category_id"
        WHERE (st0."amount" < 0)
        AND st0."status" = '#{@transaction_status_normal}'
        AND (date_trunc('month', st0."issued_at")::date = generated::date)
        AND (NOT (st0."transaction_category_id" IS NULL))
        AND st0.currency_code = 'BYN'
        GROUP BY month, st1."name"
        ORDER BY month, st0."count" DESC
        LIMIT 4) AS s1
      ON TRUE
      """)

    rows
    |> Enum.map(fn row ->
      [date, category_name, sum_amount] = row

      %{
        date: date,
        category_name: category_name,
        sum_amount: Decimal.abs(sum_amount) |> Decimal.round()
      }
    end)
    |> Enum.group_by(fn row ->
      row.category_name
    end)
    |> Enum.map(fn {category_name, category_rows} ->
      {
        category_name,
        Enum.reduce(category_rows, [], &group_by_near_months/2) |> Enum.reverse()
      }
    end)
    |> Enum.into(%{})
  end

  def list_active_users_grouped_by_month do
    {:ok, %{rows: rows}} =
      Repo.query("""
      SELECT generated::date as gen_date, active_users.c from
      generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month') AS generated
      INNER JOIN LATERAL (
        SELECT count(u.id) as c
        FROM users u
        WHERE EXISTS(
          SELECT 1
          FROM transactions t
          WHERE t.user_id = u.id
          AND (date_trunc('month', t.inserted_at)::date = generated::date))
      ) as active_users
      ON TRUE
      ORDER BY gen_date
      """)

    rows
    |> Enum.map(fn row ->
      [date, users_count] = row

      %{
        date: date,
        users_count: users_count
      }
    end)
  end

  def list_users_grouped_by_month do
    {:ok, %{rows: rows}} =
      Repo.query("""
      SELECT generated::date as gen_date, monthly_users.c from
      generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month') AS generated
      INNER JOIN LATERAL (
        SELECT count(u.id) as c
        FROM users u
        WHERE date_trunc('month', u.inserted_at)::date <= generated::date
      ) as monthly_users
      ON TRUE
      ORDER BY gen_date
      """)

    rows
    |> Enum.map(fn row ->
      [date, users_count] = row

      %{
        date: date,
        users_count: users_count
      }
    end)
  end

  defp group_by_near_months(current_row, [] = _acc) do
    [[current_row]]
  end

  defp group_by_near_months(current_row, [current_chunk | rest_chunks] = acc) do
    [last_row | _] = current_chunk

    if current_row.date.month - last_row.date.month == 1 do
      [[current_row | current_chunk] | rest_chunks]
    else
      [[current_row] | acc]
    end
  end

  def get_profit!(id), do: Repo.get!(Profit, id)

  def create_profit(attrs \\ %{}) do
    %Profit{}
    |> Profit.changeset(attrs)
    |> Repo.insert()
  end
end
