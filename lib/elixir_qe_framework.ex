defmodule ElixirQeFramework do
  @moduledoc """
  Elixir QE Framework — portfolio sample for CI / test-infrastructure ownership.

  Demonstrates patterns relevant to backend quality work in Elixir services:

  * deterministic domain unit tests
  * service-boundary / contract-style integration tests
  * flake quarantine + retry helpers (signal over noise)
  * injectable time/clock for async-free determinism
  * Mix aliases + GitHub Actions quality gates
  """

  @doc "Library version for CI / tooling banners."
  def version, do: "0.1.0"
end
