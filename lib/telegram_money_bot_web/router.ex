defmodule TelegramMoneyBotWeb.Router do
  use TelegramMoneyBotWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router
  # import Oban.Web.Router

  # sentry
  use Sentry.PlugCapture

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TelegramMoneyBotWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TelegramMoneyBotWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", TelegramMoneyBotWeb do
    pipe_through :api

    scope "/bot" do
      post "/webhook", BotController, :webhook
    end
  end

  forward("/api/mailgun_webhook", Receivex,
    adapter: Receivex.Adapter.Mailgun,
    adapter_opts: [
      api_key: Application.fetch_env!(:telegram_money_bot, :mailgun_api_key)
    ],
    handler: TelegramMoneyBot.MailgunProcessor
  )

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

    live_dashboard "/dashboard", metrics: TelegramMoneyBotWeb.Telemetry
    # oban_dashboard("/oban_dashboard")
  end
end
