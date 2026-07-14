defmodule ElixirQeFramework.ExampleFlakyTest do
  @moduledoc """
  Example quarantined test — excluded from the merge gate via `:flaky` tag.

  Run explicitly with: mix test --only flaky
  """

  use ExUnit.Case, async: true

  @tag :flaky
  test "example quarantine — always passes when run; documents the pattern" do
    # In a real suite this would be an unreliable assertion under investigation.
    # Keeping it green here so `--only flaky` still proves the tag wiring works.
    assert true
  end
end
