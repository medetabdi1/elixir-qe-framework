defmodule ElixirQeFramework.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_qe_framework,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: :cover]
    ]
  end

  def cli do
    [
      preferred_envs: [
        "test.unit": :test,
        "test.integration": :test,
        "test.ci": :test,
        "test.flake.hunt": :test,
        "quality.gate": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirQeFramework.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "test.unit": ["test --exclude integration --exclude flaky"],
      "test.integration": ["test --only integration"],
      "test.ci": ["test --exclude flaky --max-failures 1"],
      "test.flake.hunt": ["test --only flaky --repeat-until-failure 25"],
      "quality.gate": [
        "format --check-formatted",
        "credo --strict",
        "test.ci"
      ]
    ]
  end
end
