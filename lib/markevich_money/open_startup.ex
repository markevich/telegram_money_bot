defmodule MarkevichMoney.OpenStartup do
  import Ecto.Query, warn: false
  alias MarkevichMoney.Repo

  alias MarkevichMoney.OpenStartup.Profit
  alias MarkevichMoney.Transactions.Transaction
  alias MarkevichMoney.Transactions.TransactionCategory

  # SELECT *
  # FROM (select generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month')::date as m) AS t0
  # INNER JOIN LATERAL (
  #   SELECT count(st0."amount") AS "count",
  #          date_trunc('month', st0."issued_at")::date as month,
  #          st0."transaction_category_id" AS "transaction_category_id"
  #   FROM "transactions" AS st0
  #   WHERE (t0."m" = month)
  #         AND (st0."amount" < 0)
  #   GROUP BY month, st0."transaction_category_id"
  #   ORDER BY st0."transaction_category_id", month
  #   LIMIT 5
  # ) AS s1 ON TRUE

  def list_profits do
    Repo.all(Profit)
  end

  def list_profits_grouped_by_month do
    query =
      from(profit in Profit,
        select: %{
          amount: sum(profit.amount),
          date: fragment("date_trunc('month', ?)::date as month", profit.date)
        },
        group_by: fragment("month"),
        order_by: fragment("month")
      )

    Repo.all(query)
  end

  def list_incomes do
    Repo.all(from(p in Profit, where: p.amount > 0))
  end

  def list_expenses do
    Repo.all(from(p in Profit, where: p.amount < 0))
  end

  def list_popular_categories_by_month do
    {:ok, %{rows: rows}} = Repo.query(
    """
    SELECT generated::date as month, category_name, records_count from
    generate_series(date_trunc('month', current_date - interval '1 year'), date_trunc('month', current_date), '1 month') AS generated
    INNER JOIN LATERAL (
      SELECT count(st0."amount") AS "records_count",
             date_trunc('month', st0."issued_at")::date AS "month",
             st1."name" AS "category_name"
      FROM "transactions" AS st0
      INNER JOIN "transaction_categories" AS st1 ON st1."id" = st0."transaction_category_id"
      WHERE (st0."amount" < 0)
      AND (date_trunc('month', st0."issued_at")::date = generated::date)
      AND (NOT (st0."transaction_category_id" IS NULL))
      GROUP BY month, st1."name"
      ORDER BY month, st0."count" DESC
      LIMIT 3) AS s1
    ON TRUE
    """
    )

    rows
    |> Enum.map(fn (row) ->
      [month, category_name, records_count] = row

      %{
        month: month,
        category_name: category_name,
        records_count: records_count
      }
    end)
    |> Enum.group_by(fn (row) ->
      row.category_name
    end)
  end

  def list_expenses_by_month do
    #later
    query =
      from(t in Transaction,
        select: %{
          amount: sum(t.amount),
          date: fragment("date_trunc('month', ?)::date as month", t.issued_at),
          transaction_category_id: t.transaction_category_id
        },
        where: t.amount < 0,
        where: not is_nil(t.transaction_category_id),
        group_by: [fragment("month"), t.transaction_category_id],
        order_by: [t.transaction_category_id, fragment("month")]
      )

    Repo.all(query)
  end

  def get_profit!(id), do: Repo.get!(Profit, id)

  def create_profit(attrs \\ %{}) do
    %Profit{}
    |> Profit.changeset(attrs)
    |> Repo.insert()
  end
end
