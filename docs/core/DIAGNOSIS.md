# Diagnosing a core failure

A failing property, simulator seed, or golden is a correctness signal. The response is
diagnosis, not a patch.

## The protocol

### 1. Reproduce

Run the printed trace. If it is not reproducible, the trace is incomplete; fix the trace
before touching the engine.

```bash
just repro <seed>
```

### 2. Reduce

Run the reducer. The goal is the smallest op set and delivery schedule that still fails.
Record the reduced trace in the issue.

### 3. Start the 90-minute clock

From the moment the reduced trace is stable.

### 4. Write the root cause — before any fix

Four lines, in the issue:

1. **Violated rule:** `R<n>` and the exact clause.
2. **Missing test:** which property, golden, or unit should have caught it, and why it did
   not.
3. **Mutant gap:** why the sabotage suite did not kill it. If a mutant should have caught
   it, name it and strengthen it.
4. **Fix and invariant:** what changes, and which invariant it restores.

No fix without these four lines.

### 5. Fix with evidence

- The fix includes a regression test that fails before and passes after.
- If the bug was in a rule, update `RULES.md` or `ORDER.md` and add a golden.
- If the bug was in the test suite, update the mutant or the generator.
- Re-run `just sabotage`; the relevant mutant must still be killed.

### 6. Stop rule

If the clock expires without a root cause:

- **Do not guess-fix.**
- Park the ticket with the reduced trace and the four lines, marking the unknown one.
- Escalate: Fady diagnosis session, or an early RGA go/no-go if the ambiguity is systemic.
- The December 9 checkpoint is unchanged.

## Forbidden

- Changing code until the suite is green, with no root cause.
- Weakening an assertion to match the implementation.
- Deleting or skipping the failing case.
- Marking a property `skip` with a reason that is not a milestone gate.
- Saying “it passes now” without a regression test.

## Who

Fady owns the diagnosis. The agent may reproduce, reduce, and propose hypotheses. The agent
does not own the fix rationale and does not write the five-line gate.

## Template

```text
Reduced trace: <seed / op set / schedule>
Violated rule: R<n> — <clause>
Missing test: <P-xx / golden / unit> — <why it did not catch it>
Mutant gap: <id> — <why it survived / was not armed>
Fix: <change> restores <invariant>
Regression: <test name> fails before, passes after
```
