defmodule ElixirQeFramework.BookingService do
  @moduledoc """
  Application service sitting at the testable service boundary.

  Unit tests target `Appointment` pure logic.
  Integration tests target this module + `BookingStore` together.
  """

  alias ElixirQeFramework.{Appointment, BookingStore, Clock}

  @type book_attrs :: %{
          required(:client_name) => String.t(),
          required(:service) => String.t(),
          required(:starts_at) => DateTime.t(),
          required(:duration_minutes) => pos_integer(),
          optional(:notes) => String.t()
        }

  @doc "Books a new appointment if the slot is free."
  @spec book(book_attrs()) :: {:ok, Appointment.t()} | {:error, atom()}
  def book(attrs) when is_map(attrs) do
    with {:ok, appt} <- Appointment.new(Map.to_list(attrs)),
         :ok <- BookingStore.put(appt) do
      {:ok, appt}
    end
  end

  @doc "Confirms a pending appointment by id."
  @spec confirm(String.t()) :: {:ok, Appointment.t()} | {:error, atom()}
  def confirm(id) do
    case BookingStore.get(id) do
      nil ->
        {:error, :not_found}

      appt ->
        with {:ok, confirmed} <- Appointment.confirm(appt),
             :ok <- BookingStore.put(confirmed) do
          {:ok, confirmed}
        end
    end
  end

  @doc "Cancels an appointment by id."
  @spec cancel(String.t()) :: {:ok, Appointment.t()} | {:error, atom()}
  def cancel(id) do
    case BookingStore.get(id) do
      nil ->
        {:error, :not_found}

      appt ->
        with {:ok, cancelled} <- Appointment.cancel(appt),
             :ok <- BookingStore.put(cancelled) do
          {:ok, cancelled}
        end
    end
  end

  @doc "Returns whether `starts_at` is in the past relative to the injectable clock."
  @spec past?(DateTime.t()) :: boolean()
  def past?(%DateTime{} = starts_at) do
    DateTime.compare(starts_at, Clock.utc_now()) == :lt
  end
end
