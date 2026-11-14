# ADR-0003: Dumb relay plus the containment argument

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

Two devices must converge through a server. The obvious design puts merge logic on the server, because that is where the shared truth appears to live. That design creates two implementations of correctness — one in Dart, one in Go — and any disagreement between them is a silent corruption bug with no test that can see it.

PRD §08 assigns the relay a narrow job: WebSocket lifecycle, dedup, sequence assignment, durable buffering, cursor resume, metrics.

## Decision

The relay is store-and-forward and nothing more. Operations arrive as opaque JSON, land as JSONB, and leave unchanged. The relay dedups on `op_id`, assigns a per-document `seq` under a row lock, forwards to live devices, and replays backlog from a cursor. It never parses an operation, never inspects a payload, never orders by dependency.

## Alternatives considered

- **Server-side merge** — rejected: duplicates the correctness core, and the server cannot be tested against the CRDT properties.
- **Peer-to-peer transport** — rejected: NAT traversal, no durable buffer for an offline device, and no free infrastructure.
- **A CRDT library on the server** — rejected: the same duplication, plus a dependency the project forbids.

## Consequences

- **Containment:** a relay bug can delay or duplicate delivery, but cannot corrupt a document. Delay and duplication are already absorbed by the core's causal buffer (CR-04) and idempotent merge (CR-03). This is the interview-defensible argument, and it only holds while the relay stays dumb.
- Delivery is at-least-once by design. The core must remain idempotent or the whole argument collapses.
- Backpressure and batching become relay concerns, not core concerns.

## Evidence

- PRD §08 containment argument; FR-08 and FR-09 acceptance criteria.
- `scripts/architecture.sh` fails the build if `fugue`, `leftOrigin`, `left_origin`, `tieBreak`, or `NodeID` appear in relay Go source.
