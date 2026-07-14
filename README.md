# Elixir QE Framework

Portfolio sample for **CI / test-infrastructure** ownership in Elixir: service-boundary tests, flake containment, async-safe isolation, and quality gates.

> Frame: CI + unit/integration patterns engineer ramping on Elixir.  
> This repo is the ramp artifact — not a claim of prior production Elixir shipping.

**Repo:** [medetabdi1/elixir-qe-framework](https://github.com/medetabdi1/elixir-qe-framework)  
**Related:** [playwright-qe-portfolio](https://github.com/medetabdi1/playwright-qe-portfolio) (FE E2E)  
**Deep dive:** [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md)

---

## What this demonstrates

| Pattern | Where |
|--------|--------|
| Pure domain unit tests (`async: true`) | `test/unit/appointment_test.exs` |
| Service-boundary + JSON contract checks | `test/integration/` + `Testing.Boundary` |
| Per-test GenServer isolation (async-safe) | `BookingStore.bind/1` + `DataCase` |
| Deterministic time | `Clock.freeze/1` |
| ExMachina-style factories | `Testing.Factory` |
| Flake classify / hunt / quarantine registry | `Testing.Flake` + `Testing.Quarantine` |
| Mix quality gates | `mix test.ci` / `mix quality.gate` / `mix test.flake.hunt` |
| GitHub Actions | `docs/github-actions-ci.yml` (enable under `.github/workflows/` after `gh auth refresh -s workflow`) |

Domain: tiny salon booking (overlap detection, confirm/cancel, reject past starts).

---

## Quick start

```bash
mix deps.get
mix test                 # excludes :flaky by default
mix test.unit
mix test.integration
mix test --only flaky
mix test.flake.hunt      # --repeat-until-failure on quarantined tags
mix quality.gate         # format + credo + test.ci
```

Requires Elixir `~> 1.15` and OTP 26+.

---

## Layout

```
lib/elixir_qe_framework/
  appointment.ex          # pure domain
  booking_service.ex      # application service (boundary)
  booking_store.ex        # GenServer store (bindable per test)
  clock.ex                # injectable time
  testing/                # Factory · Boundary · Flake · Quarantine · Reporter
test/
  unit/ · integration/ · infrastructure/
  support/data_case.ex    # anonymous store + frozen clock
docs/HOW_IT_WORKS.md
```

---

## Criticisms we fixed (v1 → hardened)

| Weak spot | Fix |
|-----------|-----|
| Shared global store + `clear/0` (async races) | Anonymous supervised store + `bind/1` |
| No past-booking guard | `:starts_in_past` via `Clock` |
| Factory dates rot against wall clock | `DataCase` freezes clock |
| Dead quarantine registry | Real registry row + CI cover assertion |
| Case-sensitive flake classify | Case-insensitive + throw catch |
| CI workflow not on GitHub | `.github/workflows/ci.yml` restored |
| “How it works” missing | `docs/HOW_IT_WORKS.md` |

---

## CI philosophy

1. Root-cause flake — don’t “rerun until green” as policy.  
2. Quarantine is visible debt (`owner` + ticket).  
3. Right layer: unit → service boundary → E2E (QA partner).  
4. CI as product — scrape-friendly `qe_gate` lines.  
5. AI drafts OK — human review for waits/assertions/isolation.

---

## Author

**Medet Abdi** · [LinkedIn](https://linkedin.com/in/medet-abdi1/) · medet.abdi1@gmail.com
