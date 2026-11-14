# ADR-0001: Pure Dart core, not Rust + FFI

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

The foundation document specified a Rust CRDT core reached through `flutter_rust_bridge`. That plan assumed six months. The window is eight weeks (PRD §15), and the owner cannot defend Rust under questioning — which makes every merged line of it a liability rather than evidence. FFI also adds a second memory model, a cross-compilation step per Android ABI, and a class of crash the core's own tests cannot see.

PRD §08 requires the core to own all merge order, tie-breaking, causal buffering, convergence, and serialization, while importing no Flutter, no network, and no UI.

## Decision

The core is pure Dart, in `packages/weft_core`. Runtime dependency is `meta` alone. No codegen: no freezed, no build_runner, no generated parts in the correctness path. The engine is a library, not a service.

## Alternatives considered

- **Rust core + FFI** — rejected: undefendable by the owner, adds an unsafe boundary, and multiplies build complexity inside a fixed 8-week window.
- **Rust core written later, behind the same interface** — deferred: legitimate post-v1 work, explicitly out of scope now.
- **Kotlin and Swift cores** — rejected: two implementations of the same invariants, two places to be wrong.
- **A CRDT library** — rejected by the project's premise: the engine is the artifact.

## Consequences

- One language, one toolchain, one debugger across the entire correctness story.
- Raw throughput is lower than Rust. That is a measured cost, not an assumption: NFR-01 (≤16 ms render at 10k chars) and NFR-02 (≤50 ms to merge 100 ops) are benchmarked, and a miss is recorded rather than hidden.
- The architecture gate mechanically enforces the purity claim, so drift is a build failure rather than a review note.

## Evidence

- PRD §08 component table; `scripts/architecture.sh` fails on Flutter, `dart:ui`, network, or codegen imports in the core.
- NFR-01 and NFR-02 benchmarks in `docs/BENCHMARKS.md`.
