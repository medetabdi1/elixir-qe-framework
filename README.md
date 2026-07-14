# Elixir QE Framework

Portfolio sample for **CI / test-infrastructure** ownership in Elixir — the same class of work as
Boulevard’s Senior Engineer II – Quality role (service-boundary tests, flake containment, quality gates).

> Correct frame: CI + unit/integration patterns engineer who ramps on Elixir ecosystems.  
> Not claiming production Elixir shipping history — this repo *is* the ramp artifact.

**Repo:** aimed at [medetabdi1/elixir-qe-framework](https://github.com/medetabdi1/elixir-qe-framework)  
**Related:** [playwright-qe-portfolio](https://github.com/medetabdi1/playwright-qe-portfolio) (FE E2E)

---

## What this demonstrates

| Pattern | Where |
|--------|--------|
| Pure domain unit tests (fast, `async: true`) | `test/unit/appointment_test.exs` |
| Service-boundary / contract-style integration | `test/integration/booking_service_test.exs` + `Testing.Boundary` |
| Deterministic time (no wall-clock flake) | `Clock` + `test/unit/clock_test.exs` |
| Factories over shared fixtures | `Testing.Factory` |
| Flake triage helpers + bounded retry | `Testing.Flake` |
| Explicit quarantine (exclude from merge gate) | `Testing.Quarantine` + `@tag :flaky` |
| Mix quality gate aliases | `mix test.ci` / `mix quality.gate` |
| GitHub Actions: cache, format, credo, exclude flaky | `docs/github-actions-ci.yml` (copy to `.github/workflows/ci.yml` to enable Actions) |

Domain sample is a tiny salon booking service (appointments, overlap detection, confirm/cancel) —
close enough to appointment SaaS to keep stories concrete without pretending to be Boulevard’s product.

---

## Quick start

```bash
mix deps.get
mix test                 # excludes :flaky by default (see test_helper.exs)
mix test.unit            # unit only
mix test.integration     # service-boundary only
mix test --only flaky    # quarantined suite
mix quality.gate         # format + credo + test.ci
```

Requires Elixir `~> 1.15` and OTP 26+.

---

## Layout

```
lib/elixir_qe_framework/
  appointment.ex          # pure domain
  booking_service.ex      # application service (boundary)
  booking_store.ex        # in-memory GenServer store
  clock.ex                # injectable time
  testing/
    factory.ex
    flake.ex
    quarantine.ex
    boundary.ex
    reporter.ex
test/
  unit/
  integration/
  infrastructure/
  support/data_case.ex    # clears store + clock per test
```

---

## CI philosophy (interview talking points)

1. **Root-cause flake** — classify timing / shared state / data races; don’t “rerun until green” as policy.
2. **Quarantine is visible debt** — `@tag :flaky` kept out of merge gate; re-run on a secondary lane.
3. **Right layer of test** — pure units for rules; integration at the service boundary; E2E stays with QA partners.
4. **CI as product** — `qe_gate` / `qe_flake` log lines are scrape-friendly seeds for dashboards.
5. **AI with guardrails** — generate drafts, human-review assertions and isolation; never blind-merge.

---

## Author

**Medet Abdi** · [LinkedIn](https://linkedin.com/in/medet-abdi1/) · medet.abdi1@gmail.com
