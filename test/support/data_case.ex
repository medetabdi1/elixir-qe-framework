defmodule ElixirQeFramework.DataCase do
  @moduledoc """
  Shared test case for any test that touches `BookingStore`.

  Starts an **anonymous** store per test and binds it to the test process.
  That is the ExUnit-recommended isolation pattern (vs clearing a shared global),
  and it unlocks `async: true` for integration tests.

      use ElixirQeFramework.DataCase, async: true
  """

  use ExUnit.CaseTemplate

  alias ElixirQeFramework.{BookingStore, Clock}

  setup do
    # Fixed "now" so factory slots (~U[2026-08-01 ...]) stay in the future forever.
    Clock.freeze(~U[2026-07-01 12:00:00Z])

    pid =
      start_supervised!({BookingStore, name: nil, initial: %{}, id: {:booking_store, make_ref()}})

    BookingStore.bind(pid)

    on_exit(fn ->
      BookingStore.unbind()
      Clock.unfreeze()
    end)

    {:ok, store: pid}
  end
end
