# GLOSSARY.md — shared vocabulary

Live document. `/grill-with-docs` and `/domain-modeling` update it. Code names come from here.
If a term is missing, add it before using it in code.

## Domain

| Term | Meaning |
|---|---|
| **replica** | One device's copy of a document, identified by a UUID. |
| **NodeID** | `{ r: replicaUUID, c: counter }` — globally unique identity of one inserted code point. |
| **root** | Virtual node `{ r: "root", c: 0 }` anchoring the first insert. |
| **left origin** | The node an insert was placed immediately after. Basis of tie-breaking. |
| **tombstone** | A deleted node kept because other nodes may still reference it as origin. No GC in v1. |
| **op** | One insert or delete, JSON schema v1, opaque to the relay. |
| **opId** | Unique op key. Relay dedups on it; understands nothing else. |
| **delivery seq** | Relay-assigned per-document sequence number. Not a CRDT concept. |
| **cursor** | A device's last merged `delivery seq`; the resume point. |
| **causal buffer** | Holding area for ops whose dependencies have not arrived. Never dropped. |
| **merge** | Applying remote ops into local state. Commutative and idempotent. |
| **render** | Deterministic traversal producing visible text, skipping tombstones. |
| **interleaving anomaly** | Concurrent runs merged character-by-character into gibberish. Fugue exists to prevent this. |
| **maximal non-interleaving** | Concurrent same-position runs stay contiguous, ordered deterministically by NodeID. |
| **SEC** | Strong Eventual Consistency: same op set ⇒ identical state, any order. |

## System

| Term | Meaning |
|---|---|
| **weft_core** | Pure Dart correctness engine. No Flutter, no network, no codegen. |
| **relay** | Go store-and-forward service. Zero CRDT semantics. |
| **containment** | A relay bug can delay or duplicate ops but cannot corrupt a document. |
| **hint** | `connectivity_plus` signal that triggers a reconnect attempt. Never sets SYNCED. |
| **authority** | The WebSocket handshake plus completed exchange. The only thing that sets SYNCED. |
| **walking skeleton** | M0: end-to-end stub path, live before real Fugue exists. |
| **stub engine** | Sort-by-NodeID renderer. Satisfies CR-01/02/03, not CR-04/05/06. |

## Verification

| Term | Meaning |
|---|---|
| **property** | Assertion over generated op sequences (`glados`). Tags: `property`. |
| **simulator** | Hand-built seeded single-threaded scheduler injecting network faults. Tag: `simulator`. |
| **seed** | Simulator input making any failure perfectly reproducible. |
| **mutant** | A deliberately wrong merge variant. Also: *sabotage variant*. |
| **kill** | A mutant is killed when the suite fails with it applied. |
| **survive** | A mutant survives when the suite still passes — the suite is too weak. Build fails. |
| **armed / pending** | Manifest state: wired to real code, or still awaiting M1 implementation. |
| **ratchet** | Coverage may never fall below the recorded baseline. Not a percentage target. |
| **gate** | An automated check that must pass before code moves forward. Local (hooks) or remote (CI). |
| **drift** | Docs and code disagreeing. `just drift` catches the mechanical cases. |
| **defendability gate** | Fady's five own-words lines on every core PR. Agents never write it. |

## Naming rules

1. Glossary term wins over synonym. No `parent` for left origin, no `version` for delivery seq.
2. Booleans read as assertions: `isDeleted`, `hasPending`, `isArmed`.
3. Test names state the invariant: `merge is idempotent under duplicate delivery`.
4. Files are snake_case; types are UpperCamel; the glossary spelling is preserved in the type name.