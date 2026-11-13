# ADR-0006: Cursor-based delivery protocol

- Status: accepted
- Date: 2026-11-13
- Deciders: Fady Philip

## Context

A device that has been offline for a day must catch up without receiving the whole document, and without permanently missing an operation. The relay is at-least-once (ADR-0003), so a naive resume will either skip operations or redeliver forever.

## Decision

The device owns its resume point.

1. `hello` carries `docId`, `deviceId`, `roomCode`, and `lastSeq`.
2. The relay returns operations with `seq > lastSeq`, batched at ≤256 ops or ≤256 KB.
3. The device merges the batch, **persists it**, and only then sends `cursor { lastSeq }`.
4. The relay upserts the cursor and then accepts the device's pending local operations.
5. Live forwarding continues from there.

The cursor advances only after persistence. A crash between merge and persist costs a re-merge, which is free because merge is idempotent.

## Alternatives considered

- **Full document resync on every connect** — rejected: unbounded transfer on a free tier, and it hides cursor bugs rather than testing them.
- **Per-operation acknowledgement** — rejected: chattier than batching, and it makes the relay stateful in a way that survives reconnects poorly.
- **Timestamp-based last-writer-wins** — rejected: wall clocks carry no causal meaning, and a device clock skew would silently drop operations.

## Consequences

- Delivery order is transport order, not causal order. That is deliberate: the relay does not know dependencies, so the core buffers operations whose origin or delete target has not arrived (CR-04) instead of the relay trying to order them.
- The cursor is per (document, device), so a reinstalled app restarts from zero and re-merges. Correct, just wasteful — acceptable at v1.
- Backlog size is bounded by batch limits, so a 10,000-operation gap arrives in many batches rather than one oversized frame.

## Evidence

- PRD §10 message table and reconnect sequence; FR-09 acceptance: reconnect resumes exactly after the last merged batch.
- Relay integration tests assert cursor upsert and backlog rows.
