defmodule ElixirQeFramework.Testing.FactoryTest do
  use ExUnit.Case, async: true

  alias ElixirQeFramework.Clock
  alias ElixirQeFramework.Testing.Factory

  test "build_appointment! creates unique ids" do
    a = Factory.build_appointment!()
    b = Factory.build_appointment!()
    assert a.id != b.id
  end

  test "slot offsets starts_at by hours" do
    attrs = Factory.slot(3)
    assert attrs[:starts_at] == ~U[2026-08-01 13:00:00Z]
  end

  test "sequence prefixes unique suffixes" do
    assert Factory.sequence("user") =~ ~r/^user_[0-9a-f]+$/
  end

  test "future_slot is after frozen clock" do
    Clock.freeze(~U[2026-07-01 12:00:00Z])
    on_exit(&Clock.unfreeze/0)

    attrs = Factory.future_slot(2)
    assert DateTime.compare(attrs[:starts_at], Clock.utc_now()) == :gt
  end
end
