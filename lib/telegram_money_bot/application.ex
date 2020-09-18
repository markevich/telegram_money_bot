defmodule TelegramMoneyBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      TelegramMoneyBot.Repo,
      # Start the Telemetry supervisor
      TelegramMoneyBotWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TelegramMoneyBot.PubSub},
      # Start the Endpoint (http/https)
      TelegramMoneyBotWeb.Endpoint,
      # Start a worker by calling: SampleApp.Worker.start_link(arg)
      # {TelegramMoneyBot.Worker, arg}
      # Starts Oban
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TelegramMoneyBot.Supervisor]

    :ok = Oban.Telemetry.attach_default_logger()

    :telemetry.attach_many(
      "oban-errors",
      [[:oban, :job, :exception], [:oban, :circuit, :trip]],
      &ObanErrorReporter.handle_event/4,
      %{}
    )

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TelegramMoneyBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    opts = Application.get_env(:telegram_money_bot, Oban)

    # Prevent running queues or scheduling jobs from an iex console.
    if Code.ensure_loaded?(IEx) and IEx.started?() do
      opts
      |> Keyword.put(:crontab, false)
      |> Keyword.put(:queues, false)
    else
      opts
    end
  end
end
