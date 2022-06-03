defmodule MarkevichMoneyWeb.OpenStartupLive do
  use MarkevichMoneyWeb, :live_view

  alias MarkevichMoney.OpenStartup

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       profits: fetch_profits(),
       popular_categories: fetch_popular_categories(),
       most_expensive_categories: fetch_most_expensive_categories(),
       active_users_by_month: fetch_active_users_by_month(),
       users_by_month: fetch_users_by_month(),
       transactions_by_month: fetch_transactions_by_month()
     )}
  end

  defp fetch_most_expensive_categories do
    {:ok, list} =
      OpenStartup.list_most_expensive_categories_by_month()
      |> Jason.encode()

    list
  end

  defp fetch_popular_categories do
    {:ok, list} =
      OpenStartup.list_popular_categories_by_month()
      |> Jason.encode()

    list
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

  defp fetch_active_users_by_month do
    {:ok, users} =
      OpenStartup.list_active_users_grouped_by_month()
      |> Jason.encode()

    users
  end

  defp fetch_users_by_month do
    {:ok, users} =
      OpenStartup.list_users_grouped_by_month()
      |> Jason.encode()

    users
  end

  defp fetch_transactions_by_month do
    {:ok, transactions} =
      OpenStartup.list_transactions_count_grouped_by_month()
      |> Jason.encode()

    transactions
  end
end
