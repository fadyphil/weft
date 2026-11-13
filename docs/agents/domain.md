# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root. Weft is a single-context repo: one glossary, one ADR log, no per-package glossaries.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. Check `docs/adr/README.md` first — it lists every planned ADR with its milestone and status, so you can tell a decision that exists from one that is still `planned`.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## File structure

Single-context repo:

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── README.md          ← planned-ADR index
│   └── 0001-...md
├── packages/weft_core/
├── apps/weft_app/
└── relay/
```

Per-package ADRs (`packages/*/docs/adr/`) do not exist here. Do not create them; raise it with Fady if you think one is needed.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids. Weft's glossary is live: `GLOSSARY.md` says code names come from it, so an unnamed concept is a signal to add it there before using it in code.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0006 (cursor-based delivery protocol), but worth reopening because…_
