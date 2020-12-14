defmodule MarkevichMoneyWeb.OpenStartupLiveTest do
  use MarkevichMoneyWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    insert(:profit, amount: -10)
    insert(:profit, amount: 10)
    insert(:transaction)

    {:ok, page_live, disconnected_html} = live(conn, "/open")
    assert disconnected_html =~ "Денежный бот"
    assert render(page_live) =~ "Денежный бот"
  end
end
