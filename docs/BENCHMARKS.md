# Benchmarks

Numbers that are not measured under fixed conditions are anecdotes. This file records the
conditions, the budgets, and the rule that turns a number into a ticket.

The table starts empty on purpose: no engine exists yet (#2). An empty table with a known
method beats a filled table with an unknown one.

## 1. Fixed conditions

Every recorded run uses these, and a run that deviates is marked as such rather than averaged
in:

| Condition | Value |
| --- | --- |
| Machine | Dell, i7-11800H, 16 threads, 14 GB RAM, 207 GB free. |
| Power | On AC, performance governor. |
| Load | Nothing else running: no Docker, no browsers, no CI agents. |
| Build | Release/profile mode for anything on a device; AOT for Dart benchmarks. |
| Sample | Median of 5 runs. Min and max recorded next to it. |
| Dataset | 10,000-character document, 100 remote ops, unless the row says otherwise. |
| Device (mobile rows) | Snapdragon-680-class phone A, the slower of the two test phones. |
| Network (relay rows) | Render free tier, from the Dell; p95 over 20 concurrent bot devices. |

The phone is deliberately the slow one. A budget met on the faster phone is not met.

## 2. What is measured

| ID | Metric | Budget | Where it runs |
| --- | --- | --- | --- |
| NFR-01 | Render time for a 10k-char document | ≤ 16 ms | Flutter profile trace, phone A |
| NFR-02 | Merge 100 remote ops into 10k chars | ≤ 50 ms | Dart benchmark in CI (`just bench`) |
| NFR-03 | App launch to editable document | ≤ 2 s | Manual timing, release build |
| NFR-05 | Relay p95 forward latency, 20 devices | ≤ 250 ms | Go bot load smoke against Render |

NFR-04 (10,000 persisted ops without loss) and NFR-06 (CI verification time) are not latency
benchmarks; they are asserted by the simulator and by workflow timing in
[`TESTING.md`](TESTING.md).

## 3. Results

| Date | ID | Median | Min | Max | Commit | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — | No engine yet (#2). |

Every row states the commit SHA. A benchmark without a commit is a screenshot.

## 4. Regression rule

A benchmark regression opens a ticket only when **two consecutive nightly runs** are more
than **10%** worse than the recorded median. One noisy run is not evidence; the nightly
runner is a shared free-tier machine and cold starts are real.

When the rule fires, the ticket includes: the two runs, the commit range between them, the
median before and after, and whether the change was in merge, render, or transport. Guessing
at a cause without that range is not allowed.

Improvements are recorded too, with the same table. A number that only moves in the
convenient direction is not being watched.

## 5. Reproducing

```bash
just bench                          # NFR-02, on this machine
just sim 1000                       # simulator, not a benchmark but the same discipline
```

- Results are published with the seed and case counts (`WEFT_PROPERTY_CASES`,
  `WEFT_SIM_SEEDS`), so a reader can reproduce a failure exactly (DR-03).
- Relative numbers without a machine description are not accepted in a PR.
- Benchmarks are not run in CI as pass/fail gates. They inform, and the nightly rule decides.
  A flaky timing gate teaches people to re-run until green, which is worse than no gate.

## 6. Where the money goes

The three budgets map to three different failure modes: NFR-01 is the user's typing feeling
laggy, NFR-02 is reconnect feeling slow, NFR-05 is the free tier being the bottleneck rather
than the algorithm. If a budget is missed, the milestone records the miss and the decision —
including "accepted" — in `docs/devlog/` and, if it changes a design, in an ADR.
