defmodule ElixirQeFramework.Testing.FactoryTest do
  use ExUnit.Case, async: true

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
end
