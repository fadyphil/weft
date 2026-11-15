# Kernel rules

A rule is accepted only when every field is filled. `TBD` means the rule is not accepted,
and the corresponding code must not be written.

## Rule format

### R<n> — <name>

- **Status:** proposed | accepted
- **Applies to:** insert | delete | merge | render | buffer
- **Preconditions:**
- **Action:**
- **Postconditions:**
- **Invariant:** CR-xx
- **Worked example:**
- **Counterexample:**
- **Test:** P-xx / golden `<id>` / unit `<name>`
- **Mutant:** `<manifest id>` or `none yet`

---

## R1 — NodeID comparison

- **Status:** proposed
- **Applies to:** merge, render
- **Preconditions:** two `NodeID` values.
- **Action:** TBD. Define the total order: replica comparison, counter comparison, and the
  virtual root's position.
- **Postconditions:** a total order; equal IDs compare equal.
- **Invariant:** CR-01, CR-05.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** TBD.
- **Mutant:** `reverse-tiebreak`.

## R2 — Insert placement

- **Status:** proposed
- **Applies to:** merge
- **Preconditions:** an insert op with a known `leftOrigin`; the node is not already present.
- **Action:** TBD. Decide how the new node attaches relative to the existing children of its
  left origin.
- **Postconditions:** the node is in the tree exactly once; its left origin is preserved.
- **Invariant:** CR-01, CR-05.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** TBD.
- **Mutant:** `ignore-left-origin`.

## R3 — Sibling order

- **Status:** proposed
- **Applies to:** render
- **Preconditions:** a node with two or more children.
- **Action:** TBD. Decide the direction and the block rule.
- **Postconditions:** siblings render in a deterministic order; concurrent same-origin runs
  remain contiguous.
- **Invariant:** CR-05.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** P-05, golden `<id>`.
- **Mutant:** `reverse-tiebreak`, `swap-traversal-order`.

## R4 — Render traversal

- **Status:** proposed
- **Applies to:** render
- **Preconditions:** a tree with tombstones.
- **Action:** TBD. Decide the traversal order and how a tombstone's children are visited.
- **Postconditions:** every live node appears exactly once; deleted values do not appear.
- **Invariant:** CR-01, CR-06.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** golden `<id>`.
- **Mutant:** `physical-tombstone-delete`, `swap-traversal-order`.

## R5 — Delete and tombstone

- **Status:** proposed
- **Applies to:** delete
- **Preconditions:** a delete op with a known target, or an unknown target.
- **Action:** TBD. Decide the tombstone mutation and the unknown-target behaviour.
- **Postconditions:** the target is marked deleted; re-delete is a no-op; the node remains
  referenceable as an origin.
- **Invariant:** CR-03, CR-06.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** P-06, golden `<id>`.
- **Mutant:** `physical-tombstone-delete`.

## R6 — Duplicate suppression

- **Status:** proposed
- **Applies to:** merge
- **Preconditions:** an op whose `opId` has already been applied.
- **Action:** TBD. Decide the dedup key and the response to a conflicting NodeID/opId pair.
- **Postconditions:** reapplication changes nothing.
- **Invariant:** CR-03.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** P-03, golden `<id>`.
- **Mutant:** `drop-opid-dedup`, `non-idempotent-apply`.

## R7 — Causal buffering

- **Status:** proposed
- **Applies to:** buffer
- **Preconditions:** an op with an unknown `leftOrigin` or delete target.
- **Action:** TBD. Decide the buffer key, the retry trigger, and the fixpoint.
- **Postconditions:** the op is never dropped; it applies when its dependencies arrive.
- **Invariant:** CR-04.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** P-04, golden `<id>`.
- **Mutant:** `no-causal-buffer`.

## R8 — Merge fixpoint

- **Status:** proposed
- **Applies to:** merge
- **Preconditions:** a batch of local and remote ops.
- **Action:** TBD. Decide the apply/buffer loop and its termination condition.
- **Postconditions:** all applicable ops are applied; the buffer contains only blocked ops;
  a second merge of the same batch changes nothing.
- **Invariant:** CR-01, CR-02, CR-03.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** P-01, P-02, P-03.
- **Mutant:** `non-idempotent-apply`.

## R9 — Certifier predicate

- **Status:** proposed
- **Applies to:** render verification
- **Preconditions:** an op history, the engine's rendered sequence, and the canonical state.
- **Action:** TBD. Define the predicate that decides whether the sequence is the unique
  valid render of that history under R1–R4. This is the independent oracle; it must not
  call the engine's traversal.
- **Postconditions:** a boolean verdict and, on failure, the first violated clause.
- **Invariant:** CR-01, CR-05, CR-06.
- **Worked example:** TBD.
- **Counterexample:** TBD.
- **Test:** the cage's exhaustive sweep and the harness self-test.
- **Mutant:** every armed mutant; the certifier must reject each broken render.

## State equality

Convergence is asserted on both the rendered string and the canonical state. Two different
trees can render the same text. The canonical state is the set of live and tombstoned nodes,
each with its `NodeID`, `leftOrigin`, `value`, and `isDeleted` flag, sorted by the R1 order.
The test contract for that snapshot lives in `GOLDENS.md`; it is not a merge decision.
