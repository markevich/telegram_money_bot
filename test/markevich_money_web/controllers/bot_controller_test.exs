defmodule MarkevichMoneyWeb.BotControllerTest do
  use MarkevichMoneyWeb.ConnCase

  alias MarkevichMoney.Bots
  alias MarkevichMoney.Bots.Bot

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  def fixture(:bot) do
    {:ok, bot} = Bots.create_bot(@create_attrs)
    bot
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp create_bot(_) do
    bot = fixture(:bot)
    {:ok, bot: bot}
  end
end
