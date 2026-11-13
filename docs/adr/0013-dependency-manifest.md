# ADR-0013: Dependency manifest and tier policy

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

An eight-week build with a $0 budget and a single maintainer cannot absorb dependency churn.
It also cannot absorb a dependency that arrives by accident — an agent adding a convenient
package is the most likely route to an unlisted dependency, and no review catches it reliably.

A policy that lives only in prose is a policy nobody follows.

## Decision

`STACK.md` is the dependency contract, and it is machine-checked.

- Dependencies are grouped into five drift blocks: core-runtime, core-dev, app-runtime,
  app-dev, relay.
- Every block is compared against its manifest on every run of `just drift`. A mismatch fails
  the build in either direction — an undeclared package and a stale declaration both fail.
- Versions are pinned exactly, with no carets, for the build window.
- A **listed optional** package may be installed by updating `STACK.md` in the same PR. No
  ADR needed.
- Anything **unlisted** requires a new ADR and Fady's approval.
- Specific swaps are forbidden outright: `mockito` for `mocktail`, `go_router` for
  `auto_route`, `http` for `dio`, `google_fonts`, any CRDT library, FFI or Rust.

## Alternatives considered

- **Let the manifest be the truth** — rejected: a manifest records what is installed, not
  what is allowed or why. It cannot answer "may I add this?"
- **Automated dependency updates** — rejected: churn inside a frozen window, and an update
  can move the correctness core without a human deciding to.
- **No pins** — rejected: nondeterministic builds make a convergence failure unreproducible.

## Consequences

- Adding a dependency is a deliberate, visible event with a diff in `STACK.md`.
- The drift gate is only as good as the blocks. A tier that is not declared is not checked,
  so the block list is part of the contract.
- Upgrades become scheduled events rather than ambient drift.

## Evidence

- `scripts/drift.sh` compares all five blocks and reports the per-tier diff on failure.
- `STACK.md` records the reason each notable choice was made and what it replaced.
