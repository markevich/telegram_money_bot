defmodule MarkevichMoney.OpenStartup do
  import Ecto.Query, warn: false
  alias MarkevichMoney.Repo

  alias MarkevichMoney.OpenStartup.Profit

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
    Repo.all(from p in Profit, where: p.amount > 0)
  end

  def list_expenses do
    Repo.all(from p in Profit, where: p.amount < 0)
  end

  def get_profit!(id), do: Repo.get!(Profit, id)

  def create_profit(attrs \\ %{}) do
    %Profit{}
    |> Profit.changeset(attrs)
    |> Repo.insert()
  end
end
