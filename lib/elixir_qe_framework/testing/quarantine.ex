defmodule ElixirQeFramework.Testing.Quarantine do
  @moduledoc """
  Explicit quarantine registry for known-flaky tests.

  Quarantined tests stay listed, owned, and visible — not silently skipped forever.
  Wire CI with `mix test --exclude flaky` on the merge gate; run quarantined nightly.
  """

  @entries [
    # {test_module, description_fragment, owner, ticket, reason}
    {ElixirQeFramework.ExampleFlakyTest, "example quarantine", "medet", "QE-0",
     "demo entry — documents registry wiring for reviewers"}
  ]

  @doc "Returns the quarantine registry."
  @spec entries() :: [tuple()]
  def entries, do: @entries

  @doc "True when a description matches an active quarantine entry."
  @spec quarantined?(module(), String.t()) :: boolean()
  def quarantined?(module, description) when is_atom(module) and is_binary(description) do
    Enum.any?(@entries, fn {mod, fragment, _owner, _ticket, _reason} ->
      mod == module and String.contains?(description, fragment)
    end)
  end

  @doc "Human-readable quarantine report for CI summaries / dashboards."
  @spec report() :: String.t()
  def report do
    case @entries do
      [] ->
        "quarantine: 0 entries (merge gate excludes :flaky tag)"

      list ->
        lines =
          Enum.map(list, fn {mod, fragment, owner, ticket, reason} ->
            "- #{inspect(mod)} ~ \"#{fragment}\" owner=#{owner} ticket=#{ticket} reason=#{reason}"
          end)

        Enum.join(["quarantine: #{length(list)} entries" | lines], "\n")
    end
  end

  @doc "Raises unless every `@tag :flaky` module has a registry row (call from CI script)."
  @spec assert_registry_covers!([module()]) :: :ok
  def assert_registry_covers!(modules) when is_list(modules) do
    registered = MapSet.new(@entries, fn {mod, _, _, _, _} -> mod end)
    missing = Enum.reject(modules, &MapSet.member?(registered, &1))

    if missing == [] do
      :ok
    else
      raise "flaky modules missing quarantine registry entries: #{inspect(missing)}"
    end
  end
end
