defmodule MarkevichMoney.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias MarkevichMoney.Priorbank.Api

  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)

    children = [
      # Start the Ecto repository
      MarkevichMoney.Repo,
      # Start the Telemetry supervisor
      MarkevichMoneyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MarkevichMoney.PubSub},
      # Start the Endpoint (http/https)
      MarkevichMoneyWeb.Endpoint,
      # Start a worker by calling: SampleApp.Worker.start_link(arg)
      # {MarkevichMoney.Worker, arg}
      # Starts Oban
      {Oban, oban_config()},
      Api.child_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MarkevichMoney.Supervisor]

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
    MarkevichMoneyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.get_env(:markevich_money, Oban)
  end
end
