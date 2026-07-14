defmodule ElixirQeFramework.AppointmentTest do
  use ExUnit.Case, async: true

  alias ElixirQeFramework.Appointment
  alias ElixirQeFramework.Testing.Factory

  describe "new/1" do
    test "builds a pending appointment with valid attrs" do
      assert {:ok, appt} = Appointment.new(Factory.appointment_attrs())
      assert appt.status == :pending
      assert appt.service == "haircut"
    end

    test "rejects unsupported service" do
      attrs = Factory.appointment_attrs(service: "teeth-whitening")
      assert {:error, :invalid_service} = Appointment.new(attrs)
    end

    test "rejects non-positive duration" do
      attrs = Factory.appointment_attrs(duration_minutes: 0)
      assert {:error, :invalid_duration} = Appointment.new(attrs)
    end

    test "rejects missing required fields" do
      assert {:error, :missing_fields} = Appointment.new(client_name: "A")
    end
  end

  describe "confirm/1 and cancel/1" do
    test "confirm transitions pending -> confirmed" do
      appt = Factory.build_appointment!()
      assert {:ok, confirmed} = Appointment.confirm(appt)
      assert confirmed.status == :confirmed
    end

    test "confirm rejects cancelled appointments" do
      {:ok, cancelled} = Appointment.cancel(Factory.build_appointment!())
      assert {:error, :invalid_transition} = Appointment.confirm(cancelled)
    end

    test "cancel works from pending or confirmed" do
      pending = Factory.build_appointment!()
      assert {:ok, %{status: :cancelled}} = Appointment.cancel(pending)

      {:ok, confirmed} = Appointment.confirm(Factory.build_appointment!())
      assert {:ok, %{status: :cancelled}} = Appointment.cancel(confirmed)
    end
  end

  describe "overlaps?/2" do
    test "detects overlapping slots" do
      a = Factory.build_appointment!(starts_at: ~U[2026-08-01 10:00:00Z], duration_minutes: 60)
      b = Factory.build_appointment!(starts_at: ~U[2026-08-01 10:30:00Z], duration_minutes: 30)
      assert Appointment.overlaps?(a, b)
    end

    test "adjacent slots do not overlap" do
      a = Factory.build_appointment!(starts_at: ~U[2026-08-01 10:00:00Z], duration_minutes: 60)
      b = Factory.build_appointment!(starts_at: ~U[2026-08-01 11:00:00Z], duration_minutes: 30)
      refute Appointment.overlaps?(a, b)
    end
  end
end
