# ADR-0009: Cut order and the December 9 Fugue checkpoint

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

The hard wall is 2027-01-10 and it is not elastic. Eight build weeks plus four polish days
must produce a defensible artifact. Two failure modes threaten that: scope creep that quietly
adds weeks, and an unfinished engine discovered in January.

Week 4 (2026-12-09) is the point where an unfinished Tree-Fugue stops being a schedule risk
and becomes a project risk.

## Decision

**Cut order under pressure, first to die:**

1. Stretch items — already out of scope.
2. Multi-document support → one shared document.
3. Flutter polish → a bare but clean editor.
4. Demo-video production quality → a raw screen recording is acceptable.
5. Ops extras → drop elaborate dashboards and load numbers; keep CI/CD, backups, uptime.

**Never cut:** property-based convergence tests · deterministic simulator · README
design-decisions section · two-phone convergence demo. Those four are the project.

**December 9 checkpoint:** if randomized convergence property tests are not passing, fall
back to RGA, document the interleaving anomaly it exhibits, and list Fugue as future work.
The decision is made on test results, not on how close it feels.

## Alternatives considered

- **No fallback** — rejected: one algorithm becomes a single point of total failure, and the
  alternative to RGA is shipping nothing.
- **Move the wall** — impossible: military service does not reschedule.
- **Cut verification to save time** — rejected: an unverified CRDT is indistinguishable from
  a broken one, and the verification suite is the actual portfolio signal.

## Consequences

- RGA still ships a correct, tested, offline-first sync engine. What is lost is maximal
  non-interleaving (CR-05), which becomes a documented limitation with a concrete example.
- The checkpoint forces an honest mid-project measurement rather than a January surprise.
- Applying the cut order is mechanical. It is not renegotiated at the moment of pressure.

## Evidence

- Nightly property and simulator results at 2026-12-09.
- If the fallback triggers: ADR-0010 records it, and the README's known-gaps section gains
  the interleaving anomaly.
