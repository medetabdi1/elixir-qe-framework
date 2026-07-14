defmodule ElixirQeFramework.Testing.FlakeTest do
  use ExUnit.Case, async: true

  alias ElixirQeFramework.Testing.{Flake, Quarantine, Reporter}

  test "retry succeeds after transient failure" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    result =
      Flake.retry(3, fn ->
        n = Agent.get_and_update(counter, &{&1, &1 + 1})

        if n < 2 do
          raise "transient"
        else
          :ok
        end
      end)

    assert result == :ok
    assert Agent.get(counter, & &1) == 3
  end

  test "retry recovers from throw" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    result =
      Flake.retry(2, fn ->
        if Agent.get_and_update(counter, &{&1, &1 + 1}) == 0 do
          throw(:transient)
        else
          :recovered
        end
      end)

    assert result == :recovered
  end

  test "timed returns elapsed milliseconds" do
    {value, ms} = Flake.timed(fn -> :done end)
    assert value == :done
    assert is_integer(ms) and ms >= 0
  end

  test "classify maps messages to flake categories (case-insensitive)" do
    assert Flake.classify("connection TIMED OUT") == :timing
    assert Flake.classify("slot Conflict detected") == :shared_state
    assert Flake.classify("record Not Found") == :data_race
    assert Flake.classify("possible RACE") == :ordering
    assert Flake.classify("something else") == :unknown
  end

  test "quarantine registry covers demo flaky module" do
    assert Quarantine.quarantined?(
             ElixirQeFramework.ExampleFlakyTest,
             "example quarantine — always passes"
           )

    assert Quarantine.report() =~ "QE-0"
  end

  test "reporter emits scrape-friendly gate lines" do
    line =
      Reporter.gate_summary(suite: "unit", passed: 10, failed: 0, excluded: 1, duration_ms: 42)

    assert line =~ "qe_gate suite=unit"
    assert line =~ "passed=10"
  end
end
