# Testing & verification

Manual review does not catch concurrent-correctness bugs. This file is the mapping from
"it works" to "something proved it". If a claim is not checked by a layer below, it is not
true yet.

Requirements are traced by ID in §11. Every ID here exists in `PRD.md`.

## 1. Layers

| Layer | Tool | Scope | Gate |
| --- | --- | --- | --- |
| L1 unit | `dart test`, `go test` | Per-op correctness, serialization, storage recovery, relay dedup and cursor SQL. | Every PR. |
| L2 property | `glados` | Generated op sequences across replicas; assert CR-01…CR-06. | 100 cases per property per PR, 500 nightly. |
| L3 simulation | Hand-built seeded scheduler | Delay, drop, duplicate, reorder, partition; eventual delivery; convergence. | 100 seeds per PR, 1,000 nightly. |
| L4 manual | Two physical Android phones | Airplane-mode partition, arbitrary reconnect order, kill/reopen. | M3 exit and the demo video. |

L2 and L3 are infrastructure, not decoration: the sabotage suite (§6) exists to prove they
actually fail when the merge is wrong.

## 2. Rules

- **Core tests go through the public API only** — `FugueDoc` and `OpStore`. Never a private
  function, never a `src/` import. Swapping the engine must not require editing a test.
- **`package:checks`, not `expect`.** `mocktail`, not `mockito`.
- **No widget tests.** App coverage is bloc tests (`bloc_test`) plus domain and data unit
  tests. Widget tests were cut for runway, not for taste.
- **`integration_test` for single-device flows.** Two-phone flows are manual and cannot be
  automated honestly in v1.
- **Test-first for core merge and relay protocol/DB logic.** Tests-alongside for UI.
- **Test names state the invariant**, e.g. `merge is idempotent under duplicate delivery`.
- **No payload in fixtures that reaches a log**, and no production document text in tests.

## 3. Commands

| What | Command | Available |
| --- | --- | --- |
| Everything a PR must pass | `just ci` | now |
| Core unit + property | `just test-core` | after #2 |
| Property cases, explicit count | `WEFT_PROPERTY_CASES=500 just test-core` | after #2 |
| Simulator seeds | `just sim` / `just sim 1000` | after #2 |
| Relay unit + race | `just test-relay` | after #3 |
| Relay against real Postgres | `just test-relay-integration` | after #3 |
| App bloc + domain tests | `just test-app` | after #5 |
| Sabotage suite | `just sabotage` / `just sabotage --strict` | after #2 |
| Benchmarks | `just bench` | after #2 |
| Coverage | `just coverage` | after #2 |
| Two-phone script | manual, recorded in `docs/e2e.md` (added with #8) | after #6 |

`just` recipes that point at a subtree that does not exist yet report `skip: <path> absent`
rather than failing. That is a build-order state, not a pass: `WEFT_STRICT_TREE=1` refuses to
skip, and CI skips the corresponding job by name until the subtree lands (#2, #3, #5).

## 4. Properties

| ID | Property | Invariant | Generator |
| --- | --- | --- | --- |
| P-01 | Convergence | CR-01 | N replicas, random inserts and deletes, shuffled delivery. |
| P-02 | Commutativity | CR-02 | Two concurrent batches applied in both orders. |
| P-03 | Idempotence | CR-03 | The same op list applied 1–3 times. |
| P-04 | Causal buffering | CR-04 | Delete before insert; insert before origin. |
| P-05 | Non-interleaving | CR-05 | Two replicas type runs at the same origin. |
| P-06 | Tombstone integrity | CR-06 | Delete, then insert referencing the deleted origin. |

During M0 the stub engine sorts insert ops by `(replica, counter)` and skips tombstones. It
satisfies CR-01, CR-02 and CR-03 by construction. **P-04, P-05 and P-06 are skipped with the
reason `stub engine — enabled in M1`** — a skip that states why, never a silent pass.

The case count comes from `WEFT_PROPERTY_CASES` and defaults to 100. CI pins it explicitly so
a local override cannot weaken a remote run.

## 5. Simulator

Single-threaded, seeded PRNG, no wall clock, no real sockets. Faults: delay, drop, duplicate,
reorder, partition. "Drop" means delayed retransmission, never permanent loss:
`eventualDelivery: true` must deliver every unique op.

Every failure prints the seed and a minimised op trace. A bug that cannot be reproduced by
seed is not diagnosed — it is guessed at. `WEFT_SIM_SEEDS` sets the seed count (100 per PR,
1,000 nightly).

## 6. Sabotage suite

Eight deliberately wrong merge variants live in `scripts/sabotage.manifest`. Each is applied
to `packages/weft_core/lib` in turn; the property suite must fail for every one.

- **Survives** — the suite passed with the bug in place. The build fails. A surviving mutant
  is a hole in the tests, not a curiosity.
- **Broken** — the manifest's `sed` matched nothing, so the mutant was never applied. The
  build fails too; a stale manifest is a silently disarmed gate.
- **Pending** — the mutant is not wired to code yet. Allowed until M1; `--strict` forbids it,
  and `just sabotage --strict` is what M1 exit runs.

The suite replaces coverage percentage as the primary correctness gate. Property counts are
the dial that matters.

## 7. Coverage

Ratchet only: coverage may never fall below the recorded baseline. There is no headline
percentage gate and no badge to game. The baseline is locked at the end of M1.

## 8. Benchmarks

Budgeted by NFR-01, NFR-02 and NFR-05, run under the fixed conditions in
[`BENCHMARKS.md`](BENCHMARKS.md). A regression opens a ticket only after two consecutive
nightly runs exceed 10%.

## 9. Manual two-phone

The only layer that can catch what a simulator cannot: real Android lifecycle, real network
loss, real storage. Partition with airplane mode, reconnect in an arbitrary order, kill and
reopen the app, and record each run in `docs/e2e.md` (added with #8). This is required at M3 exit and for
the demo video; it is not optional evidence.

## 10. Gates

| Where | Runs |
| --- | --- |
| pre-commit | format, analyze staged files, secret scan. |
| commit-msg | Conventional Commits. |
| pre-push | `just ci`. |
| CI | `just ci` equivalent plus architecture, drift, hadolint, actionlint. |
| Nightly | 500 property cases, 1,000 simulator seeds, sabotage, security scans. |

Do not bypass a gate. A gate that cannot pass because a subtree is absent is a build-order
problem with a ticket, not a reason to weaken the gate.

## 11. Traceability

| Requirement | Verified by |
| --- | --- |
| CR-01…CR-06 | P-01…P-06, simulator, two-phone script. |
| FR-04 | Storage crash-recovery unit tests. |
| FR-08, FR-09 | Relay integration tests: dedup, cursor resume, offline buffering. |
| FR-10 | Kill/reopen device test. |
| NFR-01 | Flutter profile trace on phone A. |
| NFR-02 | Dart benchmark in CI. |
| NFR-05 | Go bot load smoke: 20 devices, p95 forward latency. |
| NFR-09 | Sentry scrubbing test; relay log review for payload absence. |
| DR-03 | Seed and case counts published with results. |

A citation to an ID that is not in `PRD.md` fails `just drift`. That is the point of this
section: traceability is checked mechanically or it is fiction.

## 12. Adding a test

1. Name the invariant, not the function.
2. Put it at the lowest layer that can catch the bug.
3. For core, use the public API. If the test needs a private symbol, the API is wrong.
4. If it guards a requirement, add or update the row in §11.
5. If it guards a bug that shipped, add a mutant to `scripts/sabotage.manifest` only when the
   merge itself was wrong; otherwise a unit test is enough.
