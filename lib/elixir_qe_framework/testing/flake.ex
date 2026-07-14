defmodule ElixirQeFramework.Testing.Flake do
  @moduledoc """
  Helpers for diagnosing and containing flaky tests — without papering them over.

  Philosophy (CI as product):
  1. Prefer root-cause fixes (timing, shared state, data races).
  2. Quarantine known flakes with `@tag :flaky` so main stays green.
  3. Use bounded retries only while investigating — never as a permanent gate.
  """

  @doc """
  Runs `fun` up to `attempts` times, returning on first success.

  Emits a warning log when a retry was required so CI can surface latent flake.
  """
  @spec retry(pos_integer(), (-> result)) :: result when result: term()
  def retry(attempts, fun) when is_integer(attempts) and attempts >= 1 and is_function(fun, 0) do
    do_retry(attempts, fun, 1, nil)
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
  Classifies a common flake root cause from a failure message.

  Not a replacement for investigation — a triage aid for dashboards / triage bots.
  """
  @spec classify(String.t()) :: atom()
  def classify(message) when is_binary(message) do
    cond do
      String.contains?(message, ["timeout", "timed out"]) -> :timing
      String.contains?(message, ["conflict", "already exists", "duplicate"]) -> :shared_state
      String.contains?(message, ["not found", "nil"]) -> :data_race
      String.contains?(message, ["order", "sequence"]) -> :ordering
      true -> :unknown
    end
  end

  defp do_retry(1, fun, _attempt, _last_error), do: fun.()

  defp do_retry(remaining, fun, attempt, _last_error) do
    fun.()
  rescue
    error ->
      require Logger

      Logger.warning(
        "flake retry attempt=#{attempt} remaining=#{remaining - 1} error=#{Exception.message(error)}"
      )

      do_retry(remaining - 1, fun, attempt + 1, error)
  end
end
