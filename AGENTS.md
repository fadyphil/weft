# AGENTS.md — Weft agent operating contract

This file is the process source of truth for AI agents working in `weft`.
`PRD.md` is the product source of truth. Where PRD v1.0 conflicts with this file on process/tooling, this file controls until the PRD amendment diff is committed.

## 1. Project snapshot

- **Name:** Weft. Repo: `weft`. License: MIT. Public from commit #1.
- **Product:** collaborative plain-text editor where offline devices always converge.
- **Engine:** hand-built Tree-Fugue CRDT in pure Dart (`packages/weft_core`). No CRDT library.
- **Client:** Flutter (`apps/weft_app`). Thin on logic, rich on UX. Zero merge logic.
- **Relay:** Go (`relay/`). Dumb store-and-forward. Zero CRDT semantics.
- **DB:** PostgreSQL. Prod: Neon free. Compute: Render free. Staging: Docker Compose on Dell.
- **Hard wall:** 2027-01-10. M0 target: 2026-11-19, buffer to 2026-11-20.
- **Budget:** $0/month. ~35 h/week build + 5 h/week devlog.

## 2. Non-goals — never implement without a new ADR and Fady approval

Tombstone GC, rich text, List-Fugue, E2EE, user accounts, undo/redo, presence/live cursors, Flutter web demo, Rust port/FFI, AI features, Play Store, background sync, notifications, charts, localization, responsive tablet/desktop layout, spec-kit, Artemis, EGM.

Stretch only if all core exit criteria are met early: List-Fugue perf comparison, presence, pub.dev publish of `weft_core`, tiny AI summarization.

## 3. Authority and stop rules

Read before acting:
1. `PRD.md`
2. `AGENTS.md`
3. `STACK.md`
4. `docs/CODING-STANDARDS.md`
5. `GLOSSARY.md`
6. relevant ADRs in `docs/adr/`
7. the current ticket/spec

Stop and ask Fady if:
- a task conflicts with PRD, this file, STACK, or an ADR;
- a skill recommends a forbidden package, pattern, or scope;
- a gate would need to be bypassed;
- a convergence failure appears;
- a secret, release, tag, merge, or branch-protection change is needed.

Do not infer permission from silence.

## 4. Process spine

Matt Pocock skills are the only process owner.

Per change:
`/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement` → `/code-review` → `/pr` → Fady merges.

Per sprint:
`/triage`, `/retro`, `/improve-codebase-architecture` as a survey only.

Convergence failure:
`/diagnosing-bugs` is mandatory. Fady owns diagnosis.

Infra/secrets:
`/wizard` may generate human-only steps. Fady executes secret provisioning.

Forbidden process tools in this repo:
- spec-kit / `specify`
- Artemis
- Elephant-Goldfish Model / EGM
- `/wayfinder`
- `/implement-spec`

The PRD is already the spec. Do not re-derive it from scratch. Entry point for M0 is `/to-tickets` against PRD M0.

## 5. Skill routing

`opencode.jsonc` is authoritative.

- Default: all skills denied.
- Allow: working set.
- Ask: situational skills; Fady approves each load.
- Deny: conflicting skills, including widget-test, FFI, go_router, manual JSON, http, localization, responsive layout, spec-kit, EGM, Artemis.

Do not delete global skills. Do not modify `~/.agents/skills`, `~/dotfiles/ai/skills`, or other agents’ directories. Project skills live in `.agents/skills/` and are committed.

When vendoring user-invoked skills, ensure OpenCode frontmatter includes:
`metadata.opencode/autoinvoke: false`

If a skill conflicts with this contract, the contract wins. Stop and report the conflict.

## 6. Git autonomy

Agent may:
- `git status`, `diff`, `log`, `show`, `branch`, `switch`, `add`, `commit`, `fetch`, `pull --ff-only`
- push feature branches only: `feat-*`, `fix-*`, `chore-*`, `docs-*`, `spike-*`
- `gh issue`, `gh pr create/view/comment/checks/diff`, `gh run view/list`, `gh repo view`, `gh label`

Agent may never:
- push to `main` or `master`
- force-push
- merge PRs
- create/delete tags
- create releases
- edit branch protection
- set secrets or variables
- run deploy hooks
- use `gh api` to mutate repo settings
- run destructive cleanup (`rm -rf`, `git reset --hard`, `git clean -fdx`)
- use `sudo`, `ssh`, `scp`, `age`, `rclone`, `psql` directly

Fady owns `main`, tags, releases, secrets, and branch protection.

Branch naming:
`feat-<issue>-slug`, `fix-<issue>-slug`, `chore-<issue>-slug`, `docs-<issue>-slug`, `spike-<issue>-slug`.

Commits:
Conventional Commits. Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, `ci`, `build`, `revert`.
Scopes: `core`, `relay`, `app`, `ops`, `docs`, `deps`, `ci`.
Reference the issue in the footer.

Never use `--no-verify` except a documented emergency approved by Fady.

## 7. Secrets

Never read, write, print, or commit:
`.env`, `.env.*`, `*.key`, `*.pem`, `*.p12`, `*.jks`, `*.keystore`, `secrets/`, SSH keys, age keys, tokens.

Only `.env.example` may exist in repo.

Sentry DSN:
- local: `--dart-define=SENTRY_DSN=...` from Fady’s shell
- CI: GitHub secret
- never committed

Backup/restore commands involving `age`, `rclone`, `pg_dump`, `pg_restore`, production `DATABASE_URL` are human-only.

## 8. Model policy

No model ID is pinned in repo config. Fady selects the session model.

Capability floor:
- core merge, tie-breaking, invariants, convergence diagnosis: frontier-class reasoning model only;
- small/flash models: scaffolding, docs, formatting, test-file structure only.

Objective check:
the sabotage suite. If a model’s merge code cannot survive it, that model does not touch core.

Every core PR records the model used, as provenance.

## 9. Dependency policy

`STACK.md` is the dependency contract.

`weft_core`:
- runtime: `meta` only
- dev: `test`, `checks`, `glados`, `coverage`, `benchmark_harness`, `fake_async`, `very_good_analysis`
- no freezed, no codegen, no Flutter imports, no network, no UI

`weft_app` required runtime:
`flutter_bloc`, `fpdart`, `get_it`, `freezed_annotation`, `json_annotation`, `auto_route`, `path`, `path_provider`, `flutter_secure_storage`, `shared_preferences`, `web_socket_channel`, `connectivity_plus`, `qr_flutter`, `mobile_scanner`, `flutter_animate`, `uuid`, `collection`, `logger`, `sentry_flutter`, `package_info_plus`, `dio`, `flutter_svg`, `characters`, `bloc_concurrency`, `device_info_plus`.

`weft_app` required dev:
`build_runner`, `freezed`, `json_serializable`, `auto_route_generator`, `bloc_test`, `mocktail`, `checks`, `test`, `integration_test`, `fake_async`, `very_good_analysis`, `build_verify`, `remove_from_coverage`.

Relay required:
`coder/websocket`, `pgx/v5`, `goose/v3`, `prometheus/client_golang`, `google/uuid`, `golang.org/x/sync`, `testify`, `golang.org/x/time/rate`.
Stdlib: `log/slog`, `crypto/sha256`.

Optional pre-approved tiers are listed in STACK.md. Installing a listed optional package requires STACK.md update + PR. Anything unlisted requires a new ADR.

Forbidden swaps:
- mockito instead of mocktail
- go_router instead of auto_route
- http instead of dio
- google_fonts
- CRDT libraries: Yjs, Automerge, Loro, crdt_lf
- FFI/Rust
- Firebase/Supabase/analytics/push/background sync

## 10. Architecture boundaries

`weft_core` owns:
merge order, tie-breaking, causal buffering, convergence, serialization, OpStore interface.

`weft_app` owns:
rendering, intent capture, persistence wiring, sync status, pairing UX.

`relay` owns:
WebSocket lifecycle, dedup, seq assignment, durable buffering, cursor resume, metrics.

Forbidden:
- merge logic in Flutter
- CRDT semantics in relay
- Flutter/network/UI imports in `weft_core`
- payload logging anywhere

CI architecture test enforces these boundaries.

## 11. Connectivity rule

`connectivity_plus` is a retry hint only. It never sets `SYNCED`.

Authority:
WebSocket handshake + backlog/pending exchange + persisted cursor.

Re-check connectivity on app resume. Android 8+ does not deliver background connectivity broadcasts reliably.

ADR-0012 records this.

## 12. Testing contract

Core:
- test through public API only: `FugueDoc`, `OpStore`
- no private-function tests
- properties assert CR-01…CR-06
- `package:checks`, not `expect`
- test-first for new behavior

Relay:
- black-box WebSocket/HTTP tests
- assert database rows
- test-first for protocol/DB logic

App:
- bloc tests with `bloc_test`
- domain/data unit tests
- no widget tests
- `integration_test` for single-device flows

Manual:
- two physical Android phones
- airplane-mode partition
- arbitrary reconnect order
- kill/reopen persistence
- recorded in `docs/e2e.md`

Sabotage suite:
8 deliberately wrong merge variants. The property suite must fail on every mutant. A surviving mutant fails the build.

Coverage:
ratchet only. Baseline locked at end of M1. No headline percentage gate.

Benchmarks:
local on Dell, median of 5, fixed conditions. Ticket opens only after two consecutive nightly regressions >10%.

## 13. Gates

Local entry point: `just`.

Expected recipes:
`bootstrap`, `doctor`, `fmt`, `lint`, `test`, `test-core`, `test-relay`, `test-app`, `sim`, `sabotage`, `bench`, `e2e`, `up`, `down`, `ci`, `adr`, `changelog`, `drift`.

Before PR:
run `just ci`.

Hooks:
- pre-commit: format, analyze staged files, secret scan
- commit-msg: Conventional Commits
- pre-push: core tests, properties, simulator smoke, Go race tests, Flutter analyze/test

CI:
mirrors pre-push plus integration, architecture test, build_verify, drift.

Drift gate (`just drift`):
- STACK packages match pubspec/go.mod
- just recipes referenced in docs exist
- allowlisted skills exist on disk
- ADR references exist
- requirement IDs cited in TESTING.md exist in PRD

Never bypass gates.

## 14. Defendability gate

Every PR touching `packages/weft_core` requires five lines written by Fady, in his own words, no file open:
1. what behavior changed;
2. why it is correct;
3. which invariant it protects;
4. which test proves it;
5. what could still break.

Agent must prompt for this text. Agent must not write it.

Final finish line:
10-minute unaided recording answering the five PRD gate questions.

## 15. Documentation

Required:
`README.md`, `PRD.md`, `AGENTS.md`, `STACK.md`, `GLOSSARY.md`, `docs/CODING-STANDARDS.md`, `docs/TESTING.md`, `docs/RUNNING.md`, `docs/BENCHMARKS.md`, `docs/SECURITY.md`, `docs/e2e.md`, `docs/adr/`, `docs/devlog/`, `CHANGELOG.md`.

ADRs:
MADR-style. Status: proposed → accepted → superseded.
Use `just adr "title"`.

Glossary:
`GLOSSARY.md` is live shared vocabulary. Name code after it.

Devlog:
weekly, `docs/devlog/NN.md` + LinkedIn post.

## 16. Release proposal protocol

Agent may propose a release only when all are true:
1. every exit criterion for the current milestone is met with linked evidence;
2. CI is green on `main`;
3. `just changelog` produces a non-empty diff.

Proposal includes:
- suggested version;
- exit-criteria checklist with proof links;
- changelog diff;
- blast-radius note.

Fady executes tag and release.

Version map:
- M0 → `v0.1.0`
- M1 → `v0.2.0`
- M2 → `v0.3.0`
- M3 → `v0.4.0`
- M4 → `v0.5.0`
- M5 → `v1.0.0`

APK attached from M2 onward.

## 17. Current phase: M0 walking skeleton

M0 exit criteria:
- public repo, CI green on main;
- relay live on Render + Neon, public URL, `/health` returns version;
- UptimeRobot pinging every 5 min;
- property harness running against stub engine;
- two physical phones exchange stub ops through live relay;
- devlog #1 posted.

Stub engine:
sort insert ops by `(replica, counter)`, skip tombstones. It must satisfy convergence, commutativity, idempotence. P-04/P-05/P-06 are skipped with reason `stub engine — enabled in M1`.

Do not start real Fugue before M0 exit.

M0 Android requirement:
AGP ≥8.12.1, Gradle ≥8.13, Java 17.

## 18. Forbidden summary

No:
- CRDT libraries
- Rust/FFI
- widget tests
- rich text
- GC
- accounts
- undo
- presence
- web demo
- Play Store
- paid services
- background sync/notifications
- spec-kit/Artemis/EGM
- payload logging
- agent-written defendability text
- merging with red CI
- cutting properties, simulator, README design decisions, or two-phone demo