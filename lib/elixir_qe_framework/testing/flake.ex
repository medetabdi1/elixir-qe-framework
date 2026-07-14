defmodule ElixirQeFramework.Testing.Flake do
  @moduledoc """
  Helpers for diagnosing and containing flaky tests — without papering them over.

  Philosophy (CI as product):
  1. Prefer root-cause fixes (timing, shared state, data races).
  2. Quarantine known flakes with `@tag :flaky` so main stays green.
  3. Use bounded retries **only while investigating** — never as a permanent merge gate.

  Native tool to hunt flakes: `mix test --repeat-until-failure N` (Elixir 1.17+).
  """

  require Logger

  @doc """
  Runs `fun` up to `attempts` times, returning on first success.

  Emits a warning when a retry was required so CI can surface latent flake.
  Investigation-only — do not wrap production CI suites in this permanently.
  """
  @spec retry(pos_integer(), (-> result)) :: result when result: term()
  def retry(attempts, fun) when is_integer(attempts) and attempts >= 1 and is_function(fun, 0) do
    do_retry(attempts, fun, 1)
  end

  @doc """
  Measures elapsed ms for a function. Useful when hunting slow/timing flakes.
  """
  @spec timed((-> result)) :: {result, non_neg_integer()} when result: term()
  def timed(fun) when is_function(fun, 0) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    {result, System.monotonic_time(:millisecond) - start}
  end

  @doc """
  Classifies a common flake root cause from a failure message (case-insensitive).

  Not a replacement for investigation — a triage aid for dashboards / triage bots.
  """
  @spec classify(String.t()) :: atom()
  def classify(message) when is_binary(message) do
    down = String.downcase(message)

    cond do
      String.contains?(down, ["timeout", "timed out"]) -> :timing
      String.contains?(down, ["conflict", "already exists", "duplicate"]) -> :shared_state
      String.contains?(down, ["not found", "nil"]) -> :data_race
      String.contains?(down, ["order", "sequence", "race"]) -> :ordering
      true -> :unknown
    end
  end

  defp do_retry(1, fun, _attempt), do: fun.()

  defp do_retry(remaining, fun, attempt) do
    fun.()
  rescue
    error ->
      Logger.warning(
        "flake retry attempt=#{attempt} remaining=#{remaining - 1} error=#{Exception.message(error)}"
      )

      do_retry(remaining - 1, fun, attempt + 1)
  catch
    kind, reason ->
      Logger.warning(
        "flake retry attempt=#{attempt} remaining=#{remaining - 1} #{kind}=#{inspect(reason)}"
      )

      do_retry(remaining - 1, fun, attempt + 1)
  end
end
