defmodule ElixirQeFramework.DataCase do
  @moduledoc """
  Shared test case for any test that touches `BookingStore`.

  Clears store state before each test so suites stay isolated —
  a primary flake root cause when skipped.
  """

  use ExUnit.CaseTemplate

  alias ElixirQeFramework.{BookingStore, Clock}

  setup do
    BookingStore.clear()
    Clock.unfreeze()

    on_exit(fn ->
      BookingStore.clear()
      Clock.unfreeze()
    end)

    :ok
  end
end
