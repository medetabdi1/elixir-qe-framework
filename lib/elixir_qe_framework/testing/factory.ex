defmodule ElixirQeFramework.Testing.Factory do
  @moduledoc """
  Deterministic test data factory.

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

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string(16) |> String.downcase()
  end
end
