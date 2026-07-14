defmodule ElixirQeFramework.Testing.Factory do
  @moduledoc """
  Deterministic test data factory (ExMachina-style, dependency-free).

  Prefer factories over shared mutable fixtures — they make failures readable
  and keep suites free of accidental coupling.
  """

  alias ElixirQeFramework.Appointment

  @doc "Builds a valid appointment attrs keyword list (does not persist)."
  @spec appointment_attrs(keyword()) :: keyword()
  def appointment_attrs(overrides \\ []) do
    base = [
      id: "appt_factory_" <> unique_suffix(),
      client_name: "Alex Client",
      service: "haircut",
      starts_at: ~U[2026-08-01 15:00:00Z],
      duration_minutes: 60,
      notes: nil
    ]

    Keyword.merge(base, overrides)
  end

  @doc "Builds a validated `%Appointment{}` or raises."
  @spec build_appointment!(keyword()) :: Appointment.t()
  def build_appointment!(overrides \\ []) do
    case Appointment.new(appointment_attrs(overrides)) do
      {:ok, appt} -> appt
      {:error, reason} -> raise "Factory build failed: #{inspect(reason)}"
    end
  end

  @doc "Builds non-overlapping slots by offsetting hours from a base time."
  @spec slot(non_neg_integer(), keyword()) :: keyword()
  def slot(hours_offset, overrides \\ []) do
    base = ~U[2026-08-01 10:00:00Z]
    starts_at = DateTime.add(base, hours_offset * 3600, :second)
    appointment_attrs(Keyword.merge([starts_at: starts_at], overrides))
  end

  @doc """
  Future slot relative to `Clock` — use in integration tests that reject past bookings.
  """
  @spec future_slot(non_neg_integer(), keyword()) :: keyword()
  def future_slot(hours_ahead \\ 24, overrides \\ []) do
    starts_at =
      ElixirQeFramework.Clock.utc_now()
      |> DateTime.add(hours_ahead * 3600, :second)
      |> DateTime.truncate(:second)

    appointment_attrs(Keyword.merge([starts_at: starts_at], overrides))
  end

  @doc """
  Monotonic sequence integer — stable within a VM run, unique across builds.
  Prefer explicit `:id` overrides when a test needs a fixed id.
  """
  @spec sequence(String.t()) :: String.t()
  def sequence(prefix) when is_binary(prefix) do
    prefix <> "_" <> unique_suffix()
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string(16) |> String.downcase()
  end
end
