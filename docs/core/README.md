# Core development: kernel and cage

This directory is the working contract for `packages/weft_core`. It exists because the
project must stay correct without a frontier-class model in the session.

It operationalizes `AGENTS.md` §8, ADR-0016, and PRD §19. It does not change them.

## The split

| Part | Owner | What it contains |
| --- | --- | --- |
| **Kernel** | Fady | The code that decides order or visibility: NodeID comparator, insert placement, sibling order, render traversal, tombstone application, causal-buffer fixpoint, and the certifier predicate. |
| **Cage** | Agent | The verification infrastructure: tree-shaped generators, exhaustive enumerator, trace/replay, reducer, golden runner, harness self-test, and simulator. |
| **Perimeter** | Agent | Everything that does not decide order or visibility: types, JSON codec, `OpStore`, `FugueDoc` facade, counters, typed errors, relay, app, CI, and docs. |

The M0 stub merge/sort is kernel, even though it is simple. Merge ordering is merge ordering.
The stub's flat `(replica, counter)` order is specified in #16; it is not the R1–R4 tree
order. The stub exists to prove the op path, not to pre-decide Fugue.

## Rules

1. **Fady authors every order or visibility decision.** The agent may draft a case list, a
   test, or a question. It may not choose the answer — not even as a placeholder.
2. **No kernel code before the rule and truth table exist.** `RULES.md` and `ORDER.md` must
   be decision-complete for the rule being implemented. `TBD` is a stop sign.
3. **No fix without a diagnosis.** A failing property follows `DIAGNOSIS.md`. The agent may
   propose hypotheses; it may not apply speculative fixes.
4. **Goldens are hand-computed.** Fady confirms every expected render in
   `packages/weft_core/test/goldens/`. The agent drafts histories, never answers.
5. **The five-line gate is mandatory.** Every core PR carries Fady's own-words lines. The
   agent prompts for them and leaves them blank.
6. **The cage is the capability arbiter.** A model that cannot kill the mutants does not
   touch core. The suite decides, not the model's self-assessment.

## Files

| File | Purpose |
| --- | --- |
| [`RULES.md`](RULES.md) | Numbered rules with preconditions, postconditions, invariants, examples, and tests. |
| [`ORDER.md`](ORDER.md) | The total order, sibling direction, traversal, and the decision table for ambiguous cases. |
| [`DIAGNOSIS.md`](DIAGNOSIS.md) | The 90-minute protocol for a failing property. |
| [`GOLDENS.md`](GOLDENS.md) | The hand-computed fixture format and index. |

## Status

Skeleton. The decisions in `ORDER.md` and the rules in `RULES.md` are `TBD` until Fady fills
them. No M1 kernel code starts until `R1`–`R4` are accepted and at least eight goldens are
confirmed.

The replay command is `just repro <seed>`. The recipe is a labelled placeholder until #17
replaces it with the real reducer-backed replay.

## Links

- `AGENTS.md` §8 — capability floor.
- ADR-0016 — model-agnostic config and the sabotage arbiter.
- ADR-0009 — cut order and the December 9 checkpoint.
- `PRD.md` §06, §09, §13 — invariants, data model, testing.
