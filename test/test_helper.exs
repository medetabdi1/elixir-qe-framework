# Test tags:
#   :integration — service-boundary / store tests (slower path)
#   :flaky — quarantined; excluded from merge gate via mix test.ci
#   :unit — optional explicit tag (default = anything without :integration)

ExUnit.start(exclude: [:flaky])

# Ensure application (and BookingStore) is running for integration tests.
{:ok, _} = Application.ensure_all_started(:elixir_qe_framework)
