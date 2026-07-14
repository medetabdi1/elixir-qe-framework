defmodule ElixirQeFramework.Clock do
  @moduledoc """
  Injectable clock so tests never depend on wall-clock timing.

  Default: `DateTime.utc_now/0` via configured `:clock` module.
  Tests: `freeze/1` / `unfreeze/0` use the process dictionary (async-safe).
  """

  @process_key {__MODULE__, :now}

  @doc "Current UTC time (injectable under test)."
  @spec utc_now() :: DateTime.t()
  def utc_now do
    case Process.get(@process_key) do
      %DateTime{} = frozen ->
        frozen

      _ ->
        clock = Application.get_env(:elixir_qe_framework, :clock, DateTime)
        clock.utc_now()
    end
  end

  @doc "Freeze time for the current process only (async-safe)."
  @spec freeze(DateTime.t()) :: :ok
  def freeze(%DateTime{} = at) do
    Process.put(@process_key, DateTime.truncate(at, :second))
    :ok
  end

  @doc "Clear any frozen time for the current process."
  @spec unfreeze() :: :ok
  def unfreeze do
    Process.delete(@process_key)
    :ok
  end

  @doc "True when time is frozen in this process."
  @spec frozen?() :: boolean()
  def frozen?, do: match?(%DateTime{}, Process.get(@process_key))
end
