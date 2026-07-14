defmodule ElixirQeFramework.ClockTest do
  use ExUnit.Case, async: true

  alias ElixirQeFramework.{BookingService, Clock}

  setup do
    Clock.unfreeze()
    on_exit(&Clock.unfreeze/0)
    :ok
  end

  test "freeze makes past?/1 deterministic" do
    Clock.freeze(~U[2026-08-01 12:00:00Z])

    assert Clock.frozen?()
    assert BookingService.past?(~U[2026-08-01 11:00:00Z])
    refute BookingService.past?(~U[2026-08-01 13:00:00Z])
  end
end
