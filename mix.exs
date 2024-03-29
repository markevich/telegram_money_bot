defmodule MarkevichMoney.MixProject do
  use Mix.Project

  def project do
    [
      app: :markevich_money,
      version: "1.4.5",
      elixir: "~> 1.13.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MarkevichMoney.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :os_mon,
        :nadia,
        :table_rex
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.10"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.7"},
      {:ecto_psql_extras, "~> 0.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.17.10"},
      {:floki, "~> 0.27", only: :test},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.3"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:nadia, git: "https://github.com/zhyu/nadia.git"},
      {:table_rex, "~> 3.1"},
      {:timex, "~> 3.5"},
      {:ex_machina, "~> 2.3", only: :test},
      {:mecks_unit, "~> 0.1", only: :test},
      {:pop3mail, "~> 1.3"},
      {:sentry, "~> 8.0"},
      {:hackney, "~> 1.8"},
      {:finch, "~> 0.6"},
      {:jason, "~> 1.1"},
      {:oban, "~> 2.15"},
      {:bebran_web, "~> 2.9", git: "git@github.com:markevich/bebran_web.git"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
