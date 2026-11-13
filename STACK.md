# STACK.md — dependency contract

Authoritative list of what may be installed. `just drift` compares the marked
blocks below against `pubspec.yaml` / `go.mod` on every PR.

- **Pinning:** exact versions, no carets, resolved during the Q60 upgrade and frozen for 8 weeks.
- **Adding a listed optional package:** update this file + PR. No new ADR needed.
- **Adding anything unlisted:** new ADR + Fady approval.
- **`weft_core` has no codegen.** No freezed, no build_runner, no generated parts.

## weft_core

Runtime: `meta` only. The correctness core must build with nothing generated in its path.

<!-- drift:begin core-runtime -->
meta
<!-- drift:end -->

<!-- drift:begin core-dev -->
benchmark_harness
checks
coverage
fake_async
glados
test
very_good_analysis
<!-- drift:end -->

## weft_app

<!-- drift:begin app-runtime -->
auto_route
bloc_concurrency
characters
collection
connectivity_plus
device_info_plus
dio
flutter_animate
flutter_bloc
flutter_secure_storage
flutter_svg
fpdart
freezed_annotation
get_it
json_annotation
logger
mobile_scanner
package_info_plus
path
path_provider
qr_flutter
sentry_flutter
shared_preferences
uuid
web_socket_channel
<!-- drift:end -->

`integration_test` comes from the Flutter SDK and is excluded from the drift comparison.

<!-- drift:begin app-dev -->
auto_route_generator
bloc_test
build_runner
build_verify
checks
fake_async
freezed
json_serializable
mocktail
remove_from_coverage
test
very_good_analysis
<!-- drift:end -->

## relay

Module paths, not import paths: `golang.org/x/time/rate` lives in module `golang.org/x/time`.

<!-- drift:begin relay -->
github.com/coder/websocket
github.com/google/uuid
github.com/jackc/pgx/v5
github.com/pressly/goose/v3
github.com/prometheus/client_golang
github.com/stretchr/testify
golang.org/x/sync
golang.org/x/time
<!-- drift:end -->

Stdlib in use: `log/slog` (structured logs), `crypto/sha256` (room-code hashing), `context`, `errors`.

## Why these and not the obvious alternative

| Choice | Rejected | Reason |
|---|---|---|
| `mocktail` | `mockito` | No codegen for mocks; bloc-ecosystem default. Overrides `dart-generate-test-mocks` guidance. |
| `checks` | `expect` | Structured failure output — decisive when a property fails on generated input. |
| `dio` | `http` | Control-plane REST only (`/join/{code}`, `/health`): interceptors, timeouts, typed error mapping. Ops stay on WebSocket. |
| `auto_route` | `go_router` | Already proven in Osserva/Trip Planner; typed routes. Overrides `flutter-setup-declarative-routing`. |
| `connectivity_plus` | `internet_connection_checker_plus` | Interface hint only; polling external endpoints costs battery and creates a second truth. Socket handshake is authority (ADR-0012). |
| bundled font assets | `google_fonts` | Runtime font download breaks offline-first. |
| `characters` | raw `String` indexing | Core stores Unicode code points; the editor works in graphemes. This package is the mapping layer. |
| `flutter_animate` | manual `AnimationController` | Declarative effects + `ShaderEffect` for GLSL. |
| `flutter_svg` | — | **Static SVG only.** No SMIL/path-morph. Animated icons need `lottie` (optional P1). |
| hand-written immutable types in core | `freezed` | Keeps the correctness path codegen-free. |

## Optional — pre-approved, install only when a ticket needs it

**P1:** `lottie`, `sentry_dio`, `share_plus`, `app_links`, `url_launcher`, `flutter_native_splash` (dev), `flutter_launcher_icons` (dev).

**P2:** `skeletonizer`, `pinput`, `dynamic_color`, `flutter_gen_runner` (dev), `vector_graphics_compiler` (dev), `permission_handler`, `formz`.

## Rejected — reversing requires an ADR

`fl_chart`, `flutter_local_notifications`, `workmanager`, `background_fetch`, `google_fonts`,
`internet_connection_checker_plus`, `rive`, `mockito`, `go_router`, `http`, `injectable`, `melos`,
`custom_lint`, `dart_code_metrics`, golden/Patrol/widget tests, Firebase, Supabase, analytics,
Crashlytics, push, code-push, home-screen widgets, audio, on-device AI, FFI/Rust, SQL or NoSQL
in core, P2P transport, message queues, gRPC, protobuf.

## Toolchain

Installed by `just bootstrap` at versions pinned in `scripts/tool-versions.env`.

| Tool | Purpose |
|---|---|
| just | single command entry point |
| lefthook | local gates |
| golangci-lint | Go lint set |
| git-cliff | changelog from Conventional Commits |
| gitleaks | secret scanning |
| govulncheck | Go vulnerability scan |
| shfmt / shellcheck | shell format + lint |
| yq | YAML parsing in `just drift` |
| age / rclone | backup encryption + upload (human-only) |
| actionlint | workflow lint |
| hadolint | Dockerfile lint (CI only) |
| postgresql-client | `pg_dump` / `pg_restore` (human-only) |
| scrcpy | phone mirroring for the demo recording |

## Platform floors

Android 8.0 / API 26 · AGP ≥ 8.12.1 · Gradle ≥ 8.13 · Java 17 · Flutter stable pinned in `.tool-versions`.