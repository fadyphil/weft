set shell := ["bash", "-cu"]
set dotenv-load := false

core  := "packages/weft_core"
app   := "apps/weft_app"
relay := "relay"
compose := "docker/compose.staging.yml"

default:
    @just --list --unsorted

# ── Setup ────────────────────────────────────────────────────────────
[group('setup')]
bootstrap:
    ./scripts/bootstrap.sh install

[group('setup')]
resolve-tools:
    ./scripts/bootstrap.sh resolve

[group('setup')]
pin-actions:
    ./scripts/bootstrap.sh pin-actions

[group('setup')]
hooks:
    lefthook install

[group('setup')]
doctor:
    ./scripts/bootstrap.sh doctor

# ── Format / lint ────────────────────────────────────────────────────
# The subtrees arrive in build order: relay (#3), core (#2), app (#5). Until one
# exists, its checks are skipped by scripts/at.sh with the missing path named,
# instead of failing on a missing directory that no change in the PR could fix.
# Set WEFT_STRICT_TREE=1 to turn a skip back into a failure.
[group('quality')]
fmt:
    ./scripts/at.sh {{core}} dart format .
    ./scripts/at.sh {{app}} dart format .
    ./scripts/at.sh {{relay}} gofmt -w .
    shfmt -w scripts

[group('quality')]
fmt-check:
    ./scripts/at.sh {{core}} dart format --output=none --set-exit-if-changed .
    ./scripts/at.sh {{app}} dart format --output=none --set-exit-if-changed .
    ./scripts/at.sh {{relay}} sh -c 'test -z "$(gofmt -l .)"'
    shfmt -d scripts

[group('quality')]
lint:
    ./scripts/at.sh {{core}} dart analyze --fatal-infos
    ./scripts/at.sh {{app}} flutter analyze
    ./scripts/at.sh {{relay}} sh -c 'go vet ./... && golangci-lint run'
    shellcheck scripts/*.sh

# ── Codegen ──────────────────────────────────────────────────────────
[group('build')]
codegen:
    ./scripts/at.sh {{app}} dart run build_runner build --delete-conflicting-outputs

# ── Tests ────────────────────────────────────────────────────────────
[group('test')]
test: test-core test-relay test-app

[group('test')]
test-core:
    ./scripts/at.sh {{core}} dart test --exclude-tags=simulator,sabotage,benchmark

[group('test')]
test-relay:
    ./scripts/at.sh {{relay}} go test -short -race ./...

[group('test')]
test-relay-integration: up
    ./scripts/at.sh {{relay}} env DATABASE_URL="$STAGING_DATABASE_URL" go test -race -run Integration ./...

[group('test')]
test-app:
    ./scripts/at.sh {{app}} flutter test

[group('test')]
sim seeds="100":
    ./scripts/at.sh {{core}} env WEFT_SIM_SEEDS={{seeds}} dart test --tags=simulator

[group('test')]
sabotage:
    @if [ -d {{core}}/lib ]; then ./scripts/sabotage.sh; else echo "skip: {{core}} absent — nothing to run"; fi

[group('test')]
coverage:
    ./scripts/at.sh {{core}} dart test --exclude-tags=simulator,sabotage,benchmark --coverage=coverage
    ./scripts/at.sh {{core}} sh -c 'dart pub global activate coverage && dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib'
    ./scripts/at.sh {{core}} sh -c "dart pub global activate remove_from_coverage && dart pub global run remove_from_coverage -f coverage/lcov.info -r '\.g\.dart$'"

[group('test')]
bench:
    ./scripts/at.sh {{core}} dart test --tags=benchmark

[group('test')]
e2e:
    @echo "Two-phone manual checklist: docs/e2e.md (record results there)."
    ./scripts/at.sh {{app}} flutter test integration_test

# ── Gates ────────────────────────────────────────────────────────────
# Every check that runs inside a subtree goes through scripts/at.sh, so an absent
# subtree is a named skip rather than a false failure. A skip protects nothing: as
# soon as the directory exists the real check runs, and WEFT_STRICT_TREE=1 forbids
# skipping entirely.
[group('gate')]
architecture:
    ./scripts/architecture.sh

[group('gate')]
drift:
    ./scripts/drift.sh

[group('gate')]
ci: fmt-check lint test-core test-relay test-app architecture drift

# ── Local infra ──────────────────────────────────────────────────────
[group('infra')]
up:
    docker compose -f {{compose}} up -d --build

[group('infra')]
down:
    docker compose -f {{compose}} down

[group('infra')]
logs:
    docker compose -f {{compose}} logs -f

[group('infra')]
migrate:
    ./scripts/at.sh {{relay}} goose -dir migrations postgres "$STAGING_DATABASE_URL" up

# ── Docs / release ───────────────────────────────────────────────────
[group('docs')]
adr title:
    ./scripts/adr.sh "{{title}}"

[group('docs')]
changelog:
    git-cliff -o CHANGELOG.md

[group('release')]
release-check:
    @echo "1. Milestone exit criteria met with linked evidence?"
    @echo "2. CI green on main?"
    @echo "3. Changelog diff non-empty?"
    git-cliff --unreleased