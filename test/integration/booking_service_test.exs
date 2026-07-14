defmodule ElixirQeFramework.BookingServiceTest do
  use ElixirQeFramework.DataCase, async: true

  @moduletag :integration

  alias ElixirQeFramework.BookingService
  alias ElixirQeFramework.Testing.{Boundary, Factory}

  test "books and confirms an appointment through the service boundary" do
    attrs = Factory.slot(0) |> Map.new()

    booked = Boundary.unwrap_ok!(BookingService.book(attrs), "book")

    Boundary.assert_contract!(
      Boundary.appointment_payload(booked),
      [:id, :client_name, :service, :starts_at, :duration_minutes, :status],
      %{status: &(&1 == :pending)}
    )

    _ = Boundary.assert_json_roundtrip!(Boundary.appointment_payload(booked))

    confirmed = Boundary.unwrap_ok!(BookingService.confirm(booked.id), "confirm")
    assert confirmed.status == :confirmed
  end

  test "rejects overlapping bookings with conflict error" do
    attrs = Factory.slot(0) |> Map.new()
    assert {:ok, _} = BookingService.book(attrs)

    overlap =
      Factory.slot(0, client_name: "Other", starts_at: ~U[2026-08-01 10:15:00Z])
      |> Map.new()

    Boundary.assert_error!(BookingService.book(overlap), :conflict)
  end

  test "rejects bookings that start in the past" do
    attrs =
      Factory.appointment_attrs(starts_at: ~U[2026-06-01 10:00:00Z])
      |> Map.new()

    Boundary.assert_error!(BookingService.book(attrs), :starts_in_past)
  end

  test "accepts string-key maps from JSON-like payloads" do
    attrs = %{
      "client_name" => "Jordan",
      "service" => "massage",
      "starts_at" => ~U[2026-08-02 14:00:00Z],
      "duration_minutes" => 45
    }

    assert {:ok, booked} = BookingService.book(attrs)
    assert booked.client_name == "Jordan"
  end

  test "returns not_found for unknown ids" do
    Boundary.assert_error!(BookingService.confirm("missing"), :not_found)
    Boundary.assert_error!(BookingService.cancel("missing"), :not_found)
  end

  test "cancel updates status via store" do
    attrs = Factory.slot(2) |> Map.new()
    {:ok, booked} = BookingService.book(attrs)
    {:ok, cancelled} = BookingService.cancel(booked.id)
    assert cancelled.status == :cancelled
  end

  test "isolated stores do not leak across bindings", %{store: store_a} do
    {:ok, _} = BookingService.book(Map.new(Factory.slot(1)))
    assert ElixirQeFramework.BookingStore.count() == 1

    store_b =
      start_supervised!({ElixirQeFramework.BookingStore, name: nil, id: :store_b_isolation})

    ElixirQeFramework.BookingStore.bind(store_b)
    assert ElixirQeFramework.BookingStore.count() == 0

    ElixirQeFramework.BookingStore.bind(store_a)
    assert ElixirQeFramework.BookingStore.count() == 1
  end
end
