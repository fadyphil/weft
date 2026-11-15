# Coding standards

The Standards axis of `/code-review` checks this file. If a rule is missing here,
the reviewer must not invent it — it should raise a ticket to add one.

## 1. Layer boundaries (enforced by `just architecture`)

| Layer | Owns | Must never |
| --- | --- | --- |
| `packages/weft_core` | merge order, tie-breaking, causal buffering, convergence, serialization, `OpStore` | import Flutter, `dart:ui`, networking, or app packages; use codegen |
| `apps/weft_app` | rendering, intent capture, persistence wiring, sync status, pairing | contain merge/ordering/conflict logic; import `package:weft_core/src/` |
| `relay` | WS lifecycle, dedup, seq assignment, buffering, cursors, metrics | interpret CRDT semantics or log payloads |

The client's only source of document text is `FugueDoc.render()`.

## 2. Naming

Use `GLOSSARY.md` terms verbatim in types, functions, files, and tests.
`leftOrigin`, not `parent` or `anchor`. `tombstone`, not `deletedFlag`.
`deliverySeq`, not `index` or `version`. If a concept has no glossary entry, add one first.

## 3. Tests

- **Through the public API only.** Core tests touch `FugueDoc` and `OpStore`, never private
  functions or `src/` files. Swapping the engine must not require editing a test.
- `package:checks`, not `expect`.
- `mocktail`, not `mockito`.
- **No widget tests.** App coverage is bloc tests (`bloc_test`) plus domain/data unit tests.
- `integration_test` for single-device flows; two-phone flows are manual (`docs/e2e.md`).
- Test-first for core and relay protocol/DB logic. Tests-alongside for UI.
- A pure refactor legitimately changes no tests. Say so in the PR.
- Tags: `property`, `simulator`, `benchmark`. Keep the default run fast.

## 4. Dart

- Dart 3 patterns and `sealed` classes for state; exhaustiveness over `default:` branches.
- Immutability by default: `final`, `const`, unmodifiable collections.
- `fpdart` `Either<Failure, T>` at every repository and use-case boundary; typed per-feature
  `Failure` classes. No bare `throw` across a layer boundary.
- `freezed` in the app only.
- No `// ignore:` without a trailing reason: `// ignore: rule — why`.
- No `print`. Use `logger`; never log document content.
- Public API gets `///` docs stating the contract, not the implementation.
- Async: no unawaited futures in logic paths; cancel every subscription in `dispose`.

## 5. Go

- `log/slog` structured logs, metadata only.
- Wrap errors: `fmt.Errorf("context: %w", err)`. Never swallow.
- `context.Context` first parameter on anything that blocks; honour cancellation.
- No `panic` outside `main` initialization.
- `errgroup` for goroutine lifecycles; every goroutine has a defined exit.
- Table-driven tests; `-race` always.
- Payload is `json.RawMessage`. Do not decode into domain types.

## 6. Security

- Never log or serialize document payloads outside the op store and the wire.
- Room codes: SHA-256 hashed at rest; treated as bearer secrets in docs.
- Secrets only via `--dart-define` locally and GitHub secrets in CI. `.env.example` only in repo.
- Sentry: scrub payloads before send.

## 7. Commits, branches, PRs

- Conventional Commits, scope from `core|relay|app|ops|docs|deps|ci`.
- Branches: `feat-<issue>-slug`, `fix-`, `chore-`, `docs-`, `spike-`.
- One ticket per PR. Self-review before requesting merge.
- `just ci` green locally before push. Never `--no-verify`.
- Core PRs carry Fady's five-line defendability gate. Agents leave it blank.
- Kernel files are listed in `docs/core/README.md`. Only Fady authors order or visibility
  logic. If a change needs a kernel decision, stop and ask.

## 8. Documentation

Every behavioural change updates the doc that describes it, in the same PR.
Decisions get an ADR. New vocabulary gets a glossary entry.
`just drift` must pass — it checks that docs and code still agree.
