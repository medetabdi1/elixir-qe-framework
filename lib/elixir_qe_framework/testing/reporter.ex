defmodule ElixirQeFramework.Testing.Reporter do
  @moduledoc """
  Tiny CI-oriented summary helpers — keep quality signal visible.

  In a real org this would push metrics to Datadog/Grafana; here we emit
  structured lines CI logs can scrape or humans can scan.
  """

  @doc "Formats a gate summary line."
  @spec gate_summary(keyword()) :: String.t()
  def gate_summary(opts) do
    suite = Keyword.fetch!(opts, :suite)
    passed = Keyword.fetch!(opts, :passed)
    failed = Keyword.get(opts, :failed, 0)
    excluded = Keyword.get(opts, :excluded, 0)
    duration_ms = Keyword.get(opts, :duration_ms, 0)

    "qe_gate suite=#{suite} passed=#{passed} failed=#{failed} excluded=#{excluded} duration_ms=#{duration_ms}"
  end

  @doc "Formats flake triage triage line."
  @spec flake_summary(atom(), String.t()) :: String.t()
  def flake_summary(classification, test_name) do
    "qe_flake class=#{classification} test=#{inspect(test_name)}"
  end
end
