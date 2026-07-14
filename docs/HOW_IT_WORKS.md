# How Elixir QE Framework works

Portfolio reference for **CI / test-infrastructure** ownership in Elixir — inspired by patterns from ExUnit, Mox (explicit contracts + isolation), ExMachina-style factories, and modern flake hygiene (`--repeat-until-failure`, quarantine lanes).

---

## Layers

1. **CI quality gate** — `format` → `credo` → `mix test.ci` (merge excludes `:flaky`; nightly runs `--only flaky`).
2. **Unit tests** — pure `Appointment` + `Clock` (`async: true`).
3. **Integration tests** — `BookingService` + bound `BookingStore` (`async: true` via per-test store).
4. **Testing helpers** — `Factory`, `Boundary`, `Flake`, `Quarantine`, `Reporter`.
5. **Domain / app** — pure appointment rules; service boundary; GenServer store; injectable clock.

## Booking request path

1. `BookingService.book/1` accepts keyword or map (atom or JSON string keys).
2. `Appointment.new/1` validates service, duration, `starts_at` (pure — fast unit tests).
3. Service rejects `:starts_in_past` via `Clock.utc_now/0` (frozen in tests).
4. `BookingStore.put/1` enforces non-overlapping **active** appointments.
5. Integration tests assert **contracts** (`Testing.Boundary`), including JSON round-trip.

## Isolation model (why parallel stays green)

| Fragile (v1) | Hardened (now) |
|--------------|----------------|
| One named global store + `clear/0` between tests | Anonymous store per test via `start_supervised!` |
| Shared mutable state → races under `async: true` | `BookingStore.bind(pid)` scopes calls to that test |
| Wall-clock `DateTime.utc_now` | `Clock.freeze/1` in `DataCase` |

This follows ExUnit guidance: only use `async: true` when tests do not mutate shared globals — and the Mox idea that collaborators should be process-scoped.

## Flake strategy

1. **Classify** failure messages (`Testing.Flake.classify/1`) for triage.
2. **Quarantine** with `@tag :flaky` + registry row (`Testing.Quarantine`, owner + ticket).
3. **Merge gate:** `mix test.ci` → `--exclude flaky`.
4. **Hunt:** `mix test.flake.hunt` → `--repeat-until-failure` (Elixir 1.17+).
5. **`Flake.retry/2`** is investigation-only — never a permanent CI policy.

## Commands

```bash
mix test                 # default: excludes :flaky
mix test.unit
mix test.integration
mix test --only flaky
mix test.flake.hunt
mix quality.gate         # format + credo + test.ci
```

## Compared to common Elixir tooling

| Tool | Role | This repo |
|------|------|-----------|
| **ExUnit** | Runner, tags, async | Core |
| **Mox** | Behaviour mocks | Pattern matched via per-test store bind |
| **ExMachina** | Factories | `Testing.Factory` (zero-dep) |
| **Wallaby / Hound** | Browser E2E | Out of scope — FE E2E stays with Playwright/QA partners |
| **ex_unit_json** | JSON CI reporters | `Testing.Reporter` seed lines (`qe_gate`, `qe_flake`) |
