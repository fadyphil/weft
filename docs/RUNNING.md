# Running Weft

What a stranger needs to clone this repo and run it. No step here requires contacting the
owner or reading a private note.

Weft has three parts: `packages/weft_core` (Dart correctness engine), `relay/` (Go
store-and-forward), `apps/weft_app` (Flutter client). At the time of writing M0 is assembling
them bottom-up, so some sections are marked **after #N**. Commands for a missing subtree
report `skip: <path> absent` instead of failing; that is expected, not an error to work
around.

## 1. Requirements

| Tool | Version | Why |
| --- | --- | --- |
| Flutter | 3.50.0 | Bundles the Dart SDK; do not install Dart separately. |
| Dart | 3.14.0 | Bundled by Flutter. |
| Go | 1.27.4 | Relay. |
| Java | 17 | Android build. AGP ≥ 8.12.1, Gradle ≥ 8.13. |
| `just` | 1.59+ | Every entry point. |
| Docker + Compose | current | Staging Postgres and relay. |
| `git`, `curl`, `jq`, `tar` | current | Bootstrap. |

The pinned set is in `.tool-versions`. `just bootstrap` installs the Go and release-binary
tools at the exact versions in `scripts/tool-versions.env`.

## 2. First run

```bash
git clone https://github.com/fadyphil/weft.git
cd weft
just bootstrap      # install pinned toolchain; re-runnable
just doctor         # prints tool / pinned version / status, plus Dart, Go, Flutter
just hooks          # install lefthook hooks (pre-commit, commit-msg, pre-push)
just ci             # the same gate a PR must pass
```

`just doctor` is the fastest way to find out why something fails: it reports `MISSING` per
tool rather than failing later with a confusing error.

## 3. Core (after #2)

```bash
just test-core                          # unit + property
WEFT_PROPERTY_CASES=500 just test-core  # heavier property run
just sim 1000                           # simulator seeds
just sabotage                           # every mutant must be killed
```

The engine is pure Dart: runtime dependency is `meta` alone, no Flutter, no network, no
codegen. If a core command asks for Flutter, something is wrong — report it.

## 4. Relay and Postgres, locally (after #3)

```bash
just up          # docker compose -f docker/compose.staging.yml up -d --build
curl -s localhost:8080/health
```

Compose publishes Postgres on **5433** (not 5432, so it cannot collide with a local
Postgres) and the relay on **8080**.

Migrations and integration tests need the staging URL in your shell:

```bash
export STAGING_DATABASE_URL='postgres://postgres:postgres@localhost:5433/weft_staging?sslmode=disable'
just migrate
just test-relay-integration
```

| Command | Does |
| --- | --- |
| `just up` | Build and start Postgres + relay. |
| `just logs` | Follow relay logs. |
| `just migrate` | Apply goose migrations. |
| `just test-relay-integration` | Black-box tests against the real database. |
| `just down` | Stop everything. Data survives in the `pgdata` volume. |

The relay parses no operations. Its job is WebSocket lifecycle, dedup, sequence numbers,
durable buffering and cursor resume. Document content must never appear in its logs.

## 5. App (after #5)

```bash
cd apps/weft_app
flutter pub get
flutter run                # connected Android device or emulator
```

Build floors are in §1. The app is a thin client: it renders what the core says and captures
intent. It contains no merge logic, and `just architecture` fails the build if it starts to.

Two-device testing is manual by design. The script is in `docs/e2e.md` (added with #8).

## 6. Gates

| Command | Meaning |
| --- | --- |
| `just fmt` / `just fmt-check` | Format, and check formatting without writing. |
| `just lint` | `dart analyze --fatal-infos`, `flutter analyze`, `go vet` + `golangci-lint`, shellcheck. |
| `just test` | All three test suites. |
| `just architecture` | PRD §08 boundaries: no Flutter in core, no merge logic in app, no CRDT in relay. |
| `just drift` | STACK vs manifests, doc recipe references, vendored skills, ADR references, requirement IDs. |
| `just ci` | Everything above, in the order a PR needs it. |

### Skips while the tree is being assembled

`just` reports `skip: <path> absent` for a subtree that does not exist yet, and `just drift`
reports `DRIFT-UNCHECKED` per manifest tier. Both are loud on purpose. To refuse to skip:

```bash
WEFT_STRICT_TREE=1 just ci
WEFT_STRICT_MANIFESTS=1 just drift
```

Issue #9 turns both on permanently once the walking skeleton exists. A missing manifest
*inside* an existing subtree always fails — that is a deletion, not a build-order state.

## 7. Troubleshooting

| Symptom | Cause |
| --- | --- |
| `skip: relay absent` | #3 has not landed. Not an error. |
| `DRIFT-UNCHECKED` | The manifest does not exist yet; see the tier named. |
| `just migrate` cannot connect | `STAGING_DATABASE_URL` not exported, or Postgres not up (`just up`). |
| Port 5433 in use | Another Postgres. Stop it, or edit the port mapping in Compose. |
| `dart: command not found` | Install Flutter, not Dart. Flutter bundles it. |
| Android build refuses AGP/Gradle | Below the floors in §1. |
| Pre-push fails but CI would pass | Run `just ci` yourself; the hook runs exactly that. |

## 8. Production

Production is Render (relay) plus Neon (Postgres), free tier, deployed from `main`. It sleeps
after ~15 minutes idle and takes about a minute to wake; the client retries and the README
says so. Deployment, secrets and backups are owner operations, not contributor steps — see
[`SECURITY.md`](SECURITY.md).
