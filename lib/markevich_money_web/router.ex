defmodule MarkevichMoneyWeb.Router do
  use MarkevichMoneyWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  # sentry
  use Sentry.PlugCapture

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MarkevichMoneyWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MarkevichMoneyWeb do
    pipe_through :browser

    live "/page", PageLive, :index
    live "/", OpenStartupLive, :index
    live "/open", OpenStartupLive, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", MarkevichMoneyWeb do
    pipe_through :api

    scope "/v1" do
      post "/transactions", TransactionsController, :create
    end

    scope "/bot" do
      post "/webhook", BotController, :webhook
    end
  end

  pipeline :admins_only do
    plug :basic_auth,
      username: System.get_env("DASHBOARD_USER"),
      password: System.get_env("DASHBOARD_PASSWORD")
  end

  scope "/" do
    if Mix.env() in [:dev, :test] do
      pipe_through :browser
    else
      pipe_through [:browser, :admins_only]
    end

    live_dashboard "/dashboard",
      metrics: MarkevichMoneyWeb.Telemetry,
      ecto_repos: [MarkevichMoney.Repo]

    oban_dashboard("/oban_dashboard")
  end
end
