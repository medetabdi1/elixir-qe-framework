defmodule ElixirQeFramework.BookingServiceTest do
  use ElixirQeFramework.DataCase

  @moduletag :integration

  alias ElixirQeFramework.BookingService
  alias ElixirQeFramework.Testing.{Boundary, Factory}

  test "books and confirms an appointment through the service boundary" do
    attrs =
      Factory.appointment_attrs()
      |> Enum.into(%{})

    booked = Boundary.unwrap_ok!(BookingService.book(attrs), "book")

    Boundary.assert_contract!(
      Boundary.appointment_payload(booked),
      [:id, :client_name, :service, :starts_at, :duration_minutes, :status],
      %{status: &(&1 == :pending)}
    )

    confirmed = Boundary.unwrap_ok!(BookingService.confirm(booked.id), "confirm")
    assert confirmed.status == :confirmed
  end

  test "rejects overlapping bookings with conflict error" do
    attrs = Factory.slot(0) |> Enum.into(%{})
    assert {:ok, _} = BookingService.book(attrs)

    overlap =
      Factory.slot(0, client_name: "Other", starts_at: ~U[2026-08-01 10:15:00Z])
      |> Enum.into(%{})

    Boundary.assert_error!(BookingService.book(overlap), :conflict)
  end

  test "returns not_found for unknown ids" do
    Boundary.assert_error!(BookingService.confirm("missing"), :not_found)
    Boundary.assert_error!(BookingService.cancel("missing"), :not_found)
  end

  test "cancel updates status via store" do
    attrs = Factory.slot(2) |> Enum.into(%{})
    {:ok, booked} = BookingService.book(attrs)
    {:ok, cancelled} = BookingService.cancel(booked.id)
    assert cancelled.status == :cancelled
  end
end
