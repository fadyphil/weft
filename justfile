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
[group('quality')]
fmt:
    cd {{core}} && dart format .
    cd {{app}} && dart format .
    cd {{relay}} && gofmt -w .
    shfmt -w scripts

[group('quality')]
fmt-check:
    cd {{core}} && dart format --output=none --set-exit-if-changed .
    cd {{app}} && dart format --output=none --set-exit-if-changed .
    cd {{relay}} && test -z "$(gofmt -l .)"
    shfmt -d scripts

[group('quality')]
lint:
    cd {{core}} && dart analyze --fatal-infos
    cd {{app}} && flutter analyze
    cd {{relay}} && go vet ./... && golangci-lint run
    shellcheck scripts/*.sh

# ── Codegen ──────────────────────────────────────────────────────────
[group('build')]
codegen:
    cd {{app}} && dart run build_runner build --delete-conflicting-outputs

# ── Tests ────────────────────────────────────────────────────────────
[group('test')]
test: test-core test-relay test-app

[group('test')]
test-core:
    cd {{core}} && dart test --exclude-tags=simulator,sabotage,benchmark

[group('test')]
test-relay:
    cd {{relay}} && go test -short -race ./...

[group('test')]
test-relay-integration: up
    cd {{relay}} && DATABASE_URL="$STAGING_DATABASE_URL" go test -race -run Integration ./...

[group('test')]
test-app:
    cd {{app}} && flutter test

[group('test')]
sim seeds="100":
    cd {{core}} && WEFT_SIM_SEEDS={{seeds}} dart test --tags=simulator

[group('test')]
sabotage:
    ./scripts/sabotage.sh

[group('test')]
coverage:
    cd {{core}} && dart test --exclude-tags=simulator,sabotage,benchmark --coverage=coverage
    cd {{core}} && dart pub global activate coverage && dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    cd {{core}} && dart pub global activate remove_from_coverage && dart pub global run remove_from_coverage -f coverage/lcov.info -r '\.g\.dart$'

[group('test')]
bench:
    cd {{core}} && dart test --tags=benchmark

[group('test')]
e2e:
    @echo "Two-phone manual checklist: docs/e2e.md (record results there)."
    cd {{app}} && flutter test integration_test

# ── Gates ────────────────────────────────────────────────────────────
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
    cd {{relay}} && goose -dir migrations postgres "$STAGING_DATABASE_URL" up

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