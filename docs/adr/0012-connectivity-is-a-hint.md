# ADR-0012: Connectivity is a hint; the socket is authority

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

`connectivity_plus` reports whether a network interface is up. It does not report whether the
relay is reachable, whether the handshake succeeded, or whether the backlog was exchanged.
Treating it as online state creates a second source of truth, and the two disagree exactly
when it matters — captive portals, sleeping sockets, cold-starting free-tier compute.

Android 8+ does not deliver background connectivity broadcasts reliably either, so the signal
is not even dependable on its own terms.

## Decision

The connectivity signal is a **hint** that triggers a reconnect attempt. It never sets a
status on its own.

`SYNCED` is set only by: WebSocket handshake completed, backlog merged, pending local
operations acknowledged, and cursor persisted. `OFFLINE`, `SYNCING`, and `RETRYING` are
likewise derived from the socket lifecycle, never from the connectivity plugin.

Connectivity is re-checked on app resume, because background broadcasts are unreliable.

## Alternatives considered

- **Trust `connectivity_plus` for online state** — rejected: it lies in every case that
  matters, and a UI that says SYNCED while a socket is dead is worse than one that says
  nothing.
- **Poll an external endpoint** — rejected: costs battery, needs a network call to decide
  whether to make network calls, and creates the same second truth.
- **No connectivity listener at all** — rejected: misses legitimate reconnect opportunities
  and delays recovery after a network change.

## Consequences

- The badge can read OFFLINE while the interface is up, and that is correct.
- Every status transition is testable against the socket state machine rather than mocked
  plugin events.
- The UI must tolerate `connectivity == true` with a dead socket without flickering to
  SYNCED.

## Evidence

- PRD §10 connection lifecycle; FR-06 acceptance: status transitions match the lifecycle.
- FR-07 two-phone reconnect test in either order.
