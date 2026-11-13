## Summary

<!-- Smallest visual that makes the change clear: diagram, table, or 3 bullets. -->

## Behavior change

**What behavior changed?**

**Which test proves it?**

<!-- "Pure refactor — existing suite proves it" is a valid answer. -->

## Evidence

| Before | After |
| --- | --- |
| <!-- output / screenshot / number --> | <!-- output / screenshot / number --> |

- [ ] `just ci` green locally
- [ ] No new dependency, or STACK.md updated / ADR linked
- [ ] No non-goal introduced (PRD §03)
- [ ] No document payload logged

## Merge danger

- Door: <!-- one-way / two-way -->
- Blast radius: <!-- core / relay / app / ops -->

## Defendability gate — required if this PR touches `packages/weft_core`

<!-- Fady writes these five lines himself, no file open. Agents must leave this blank. -->

1. What behavior changed:
2. Why it is correct:
3. Which invariant it protects:
4. Which test proves it:
5. What could still break:

## Provenance

- Model used:
- Agent-authored files:
- Human-authored files:

Closes #