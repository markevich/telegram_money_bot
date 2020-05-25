defmodule MarkevichMoneyWeb.Router do
  use MarkevichMoneyWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  # sentry
  use Plug.ErrorHandler
  use Sentry.Plug

  #

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
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

    live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", MarkevichMoneyWeb do
    pipe_through :api

    scope "/bot" do
      post "/webhook", BotController, :webhook
    end
  end

  forward("/api/mailgun_webhook", Receivex,
    adapter: Receivex.Adapter.Mailgun,
    adapter_opts: [
      api_key: Application.fetch_env!(:markevich_money, :mailgun_api_key)
    ],
    handler: MarkevichMoney.MailgunProcessor
  )

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).

  pipeline :admins_only do
    plug :basic_auth,
      username: System.get_env("DASHBOARD_USER"),
      password: System.get_env("DASHBOARD_PASSWORD")
  end

  scope "/" do
    if Mix.env() in [:dev, :test] do
      pipe_through :browser
    else
      pipe_through :admins_only
    end

    live_dashboard "/dashboard", metrics: MarkevichMoneyWeb.Telemetry
  end
end
