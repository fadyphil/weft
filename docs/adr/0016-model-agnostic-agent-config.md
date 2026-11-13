# ADR-0016: Model-agnostic agent config with a capability floor

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

Model capabilities move faster than this repository will. A pinned model ID in repo config
rots within weeks, blocks upgrades, and quietly encodes an assumption about which model is
available on a given day.

But "any model may do anything" is worse. Merge ordering and tie-breaking are the parts of
this project that cannot be checked by reading the diff, and a plausible-looking merge that
is subtly wrong passes review and fails months later under a property test.

## Decision

**No model ID is pinned in repo config.** Fady selects the session model.

**Capability floor:**

- Core merge, tie-breaking, invariants, and convergence diagnosis: a frontier-class reasoning
  model only.
- Small and flash models: scaffolding, docs, formatting, test-file structure.

**Objective check:** the sabotage suite. If a model's merge code cannot kill all eight armed
mutants, that model does not touch core — the suite is the arbiter, not the model's
self-assessment.

**Provenance:** every core PR records the model used.

## Alternatives considered

- **Pin a model in config** — rejected: rots, blocks upgrades, and turns a routing decision
  into a repository change.
- **Let any model write core, catch it in review** — rejected: review cannot see a wrong
  tie-break that converges on the tested cases.
- **No provenance record** — rejected: without it, a later convergence failure cannot be
  traced to the change that introduced it.

## Consequences

- A flash model producing core merge code is a process violation even if the tests pass.
- The capability floor depends on the sabotage suite actually being armed. Until M1 arms all
  eight mutants, the floor is enforced by discipline alone — which is why arming them is an
  M1 exit criterion, not a nice-to-have.
- Model choice becomes a per-session decision with a recorded audit trail rather than a
  configuration constant.

## Evidence

- PR template carries a model field for core PRs.
- `scripts/sabotage.manifest` defines the eight mutants; `just sabotage` fails on a survivor.
- `AGENTS.md` §8 records the floor.
