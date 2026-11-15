# Goldens

A golden is a small op history with a hand-computed expected render and canonical state. It
is the independent oracle: random properties and mutants cannot catch a shared
misunderstanding between the engine and its test generator; a hand-computed answer can.

## Rules

1. Fady computes or confirms every `expected` and `expectedState`. The agent drafts the
   history and the format only.
2. Every ambiguity in `ORDER.md` gets a golden before the kernel code is written.
3. A golden changes only with a decision record in `ORDER.md` and a note in the PR.
4. Goldens are small. If a golden needs more than about six ops, split it.

## Format

`packages/weft_core/test/goldens/<id>.json`

```json
{
  "id": "G03",
  "description": "two concurrent inserts after root",
  "ops": [
    {
      "v": 1,
      "opId": "r1:1",
      "kind": "ins",
      "id": { "r": "r1", "c": 1 },
      "left": { "r": "root", "c": 0 },
      "value": "B"
    }
  ],
  "delivery": ["r1:1"],
  "expected": "B",
  "expectedState": [
    {
      "id": { "r": "r1", "c": 1 },
      "left": { "r": "root", "c": 0 },
      "value": "B",
      "isDeleted": false
    }
  ],
  "confirmedBy": "Fady",
  "date": "YYYY-MM-DD"
}
```

- `delivery` is the order the ops are merged. Omit it to mean the declared order.
- `expectedState` is sorted by the R1 order. It is the state-equality assertion, not just
  the render.
- A fixture with `confirmedBy` or `date` empty is a draft, not a golden. The runner must
  reject drafts in CI.
- The JSON uses schema v1 exactly as `PRD.md` §09 defines it. Do not invent a test-only op
  shape.

## Index

| ID | Case | Invariant | Status |
| --- | --- | --- | --- |
| G01 | root insert | CR-01 | draft |
| G02 | sequential insert after a node | CR-01 | draft |
| G03 | concurrent inserts after root | CR-05 | draft |
| G04 | child of one of two concurrent siblings | CR-05 | draft |
| G05 | delete a middle node | CR-01 | draft |
| G06 | delete a node with a child | CR-06 | draft |
| G07 | insert after a tombstone | CR-06 | draft |
| G08 | duplicate insert delivery | CR-03 | draft |
| G09 | delete before insert | CR-04 | draft |
| G10 | same replica counter gap | CR-01 | draft |
| G11 | three concurrent runs at one origin | CR-05 | draft |
| G12 | nested concurrent runs | CR-05 | draft |

At least G01–G08 must be confirmed before M1 kernel code starts.
