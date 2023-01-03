defmodule MarkevichMoneyWeb.TransactionsController do
  use MarkevichMoneyWeb, :controller
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Users

  def create(conn, attrs) do
    user = Users.get_user_by_token!(attrs["api_token"])

    attrs
    |> Map.put("user_id", user.id)
    |> Transactions.create_from_api()

    text(conn, "ok")
  end
end
