defmodule MarkevichMoneyWeb.PageController do
  use MarkevichMoneyWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
