defmodule MarkevichMoneyWeb.Router do
  use MarkevichMoneyWeb, :router
  #sentry
  use Plug.ErrorHandler
  use Sentry.Plug
  #

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", MarkevichMoneyWeb do
  # pipe_through :browser
  # end

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
end
