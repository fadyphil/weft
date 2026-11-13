# ADR-0014: Skill routing — default-deny with an explicit allowlist

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

The agent's skill library contains conflicting instructions. Some assume widget tests, some
assume FFI, some assume `go_router`, some assume `http`. Several would silently reverse
decisions this project has made deliberately. A skill's instructions are loaded as
authority, so a conflicting skill does not lose an argument — it wins one.

Telling the agent "don't use those" in prose does not survive contact with a skill body that
says otherwise.

## Decision

`opencode.jsonc` is authoritative for skill routing, and it is default-deny.

- **Allow:** the working set — the process spine, core Dart, relay Go, testing, architecture.
- **Ask:** situational skills. Fady approves each load.
- **Deny:** everything that conflicts with this project, explicitly including widget-test,
  FFI, `go_router`, manual JSON, `http`, localization, responsive layout, spec-kit, EGM,
  Artemis, and wayfinder.

Conflicting skills are **denied, not deleted** — they are shared with other repositories.
Project skills live in `.agents/skills/` and are committed.

Vendored user-invoked skills carry `metadata.opencode/autoinvoke: false` so they load only
when invoked, never by inference.

## Alternatives considered

- **Allow everything and instruct in `AGENTS.md`** — rejected: a loaded skill body outranks a
  prose instruction, and the conflict surfaces as silent scope drift.
- **Delete conflicting skills** — rejected: destructive to other repositories and to the
  user's global setup.
- **Allow everything, review the output** — rejected: review cannot see which skill produced
  a decision, so the drift is unattributable.

## Consequences

- Adding a skill is a two-file change: vendor it, then route it. A skill on disk that is not
  routed is inert, and the drift gate fails if a routed skill is missing from disk.
- A skill that conflicts with the contract is a stop-and-report event, not a judgement call.
- The allowlist is auditable in one file and cannot rot silently.

## Evidence

- `scripts/drift.sh` cross-checks every allow/ask skill in `opencode.jsonc` against
  `.agents/skills/` and fails on a missing one.
- `AGENTS.md` §5 records the routing rules the config implements.
