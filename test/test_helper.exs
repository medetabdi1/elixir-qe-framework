# Test tags:
#   :integration — service-boundary / store tests
#   :flaky — quarantined; excluded from merge gate via mix test.ci

ExUnit.start(exclude: [:flaky])

{:ok, _} = Application.ensure_all_started(:elixir_qe_framework)

# Fail CI prep if a flaky-tagged demo module loses its quarantine registry row.
ElixirQeFramework.Testing.Quarantine.assert_registry_covers!([
  ElixirQeFramework.ExampleFlakyTest
])

IO.puts(ElixirQeFramework.Testing.Quarantine.report())
