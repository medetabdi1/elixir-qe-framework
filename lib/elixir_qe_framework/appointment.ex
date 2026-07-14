defmodule ElixirQeFramework.Appointment do
  @moduledoc """
  Pure domain model for a salon/spa appointment booking.

  Kept free of process / DB concerns so unit tests stay fast and deterministic.
  """

  @enforce_keys [:id, :client_name, :service, :starts_at, :duration_minutes, :status]
  defstruct [:id, :client_name, :service, :starts_at, :duration_minutes, :status, :notes]

  @type status :: :pending | :confirmed | :cancelled | :completed
  @type t :: %__MODULE__{
          id: String.t(),
          client_name: String.t(),
          service: String.t(),
          starts_at: DateTime.t(),
          duration_minutes: pos_integer(),
          status: status(),
          notes: String.t() | nil
        }

  @valid_services ~w(haircut color facial massage manicure)

  @doc "Creates a pending appointment when inputs are valid."
  @spec new(keyword()) :: {:ok, t()} | {:error, atom()}
  def new(attrs) when is_list(attrs) do
    with :ok <- require_keys(attrs, [:client_name, :service, :starts_at, :duration_minutes]),
         :ok <- validate_service(Keyword.fetch!(attrs, :service)),
         :ok <- validate_duration(Keyword.fetch!(attrs, :duration_minutes)),
         :ok <- validate_starts_at(Keyword.fetch!(attrs, :starts_at)) do
      {:ok,
       %__MODULE__{
         id: Keyword.get_lazy(attrs, :id, &generate_id/0),
         client_name: Keyword.fetch!(attrs, :client_name),
         service: Keyword.fetch!(attrs, :service),
         starts_at: Keyword.fetch!(attrs, :starts_at),
         duration_minutes: Keyword.fetch!(attrs, :duration_minutes),
         status: :pending,
         notes: Keyword.get(attrs, :notes)
       }}
    end
  end

  @doc "Marks an appointment confirmed."
  @spec confirm(t()) :: {:ok, t()} | {:error, :invalid_transition}
  def confirm(%__MODULE__{status: :pending} = appt), do: {:ok, %{appt | status: :confirmed}}
  def confirm(%__MODULE__{}), do: {:error, :invalid_transition}

  @doc "Cancels a pending or confirmed appointment."
  @spec cancel(t()) :: {:ok, t()} | {:error, :invalid_transition}
  def cancel(%__MODULE__{status: status} = appt) when status in [:pending, :confirmed] do
    {:ok, %{appt | status: :cancelled}}
  end

  def cancel(%__MODULE__{}), do: {:error, :invalid_transition}

  @doc "True when two appointments overlap in time."
  @spec overlaps?(t(), t()) :: boolean()
  def overlaps?(%__MODULE__{} = a, %__MODULE__{} = b) do
    a_end = DateTime.add(a.starts_at, a.duration_minutes * 60, :second)
    b_end = DateTime.add(b.starts_at, b.duration_minutes * 60, :second)

    DateTime.compare(a.starts_at, b_end) == :lt and DateTime.compare(b.starts_at, a_end) == :lt
  end

  @doc "Returns the list of supported services."
  def valid_services, do: @valid_services

  defp require_keys(attrs, keys) do
    missing = Enum.reject(keys, &Keyword.has_key?(attrs, &1))

    case missing do
      [] -> :ok
      _ -> {:error, :missing_fields}
    end
  end

  defp validate_service(service) when service in @valid_services, do: :ok
  defp validate_service(_), do: {:error, :invalid_service}

  defp validate_duration(minutes) when is_integer(minutes) and minutes > 0 and minutes <= 240,
    do: :ok

  defp validate_duration(_), do: {:error, :invalid_duration}

  defp validate_starts_at(%DateTime{}), do: :ok
  defp validate_starts_at(_), do: {:error, :invalid_starts_at}

  defp generate_id do
    "appt_" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
  end
end
