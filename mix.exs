defmodule Datix.MixProject do
  use Mix.Project

  @github "https://github.com/hrzndhrn/datix"

  def project do
    [
      app: :datix,
      version: "0.1.1",
      elixir: "~> 1.11",
      description: description(),
      source_url: @github,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      package: package(),
      deps: deps()
    ]
  end

  def description do
    "A date-time parser using `Calendar.strftime` format strings."
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp dialyzer do
    [
      flags: [:unmatched_returns, :error_handling],
      plt_file: {:no_warn, "test/support/plts/dialyzer.plt"}
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp deps do
    [
      # dev and test
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_cldr_calendars_coptic, "~> 0.2", only: [:dev, :test]},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test, runtime: false},
      {:prove, "~> 0.1", only: [:dev, :test]}
    ]
  end
end
