defmodule MarkevichMoneyWeb.OpenStartupLive do
  use MarkevichMoneyWeb, :live_view

  alias MarkevichMoney.OpenStartup

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       incomes: fetch_incomes(),
       expenses: fetch_expenses(),
       profits: fetch_profits(),
       popular_categories: fetch_popular_categories()
     )}
  end


  defp fetch_popular_categories do
    {:ok, list} =
      OpenStartup.list_popular_categories_by_month()
      |> Jason.encode()

    list
  end

  defp fetch_incomes do
    {:ok, incomes} =
      OpenStartup.list_incomes()
      |> Enum.map(&map_profit/1)
      |> Jason.encode()

    incomes
  end

  defp fetch_expenses do
    {:ok, expenses} =
      OpenStartup.list_expenses()
      |> Enum.map(&map_profit/1)
      |> Jason.encode()

    expenses
  end

  defp fetch_profits do
    {:ok, profits} =
      OpenStartup.list_profits_grouped_by_month()
      |> Enum.map(fn profit ->
        %{
          amount: profit.amount,
          date: profit.date
        }
      end)
      |> Jason.encode()

    profits
  end

  defp map_profit(profit) do
    %{
      amount: profit.amount,
      date: profit.date,
      description: profit.description
    }
  end
end
