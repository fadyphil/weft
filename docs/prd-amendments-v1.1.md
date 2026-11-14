# PRD amendments — v1.0 → v1.1

Apply by replacing the named blocks in `PRD.md`, then set the version field to **1.1**.
Delivered as explicit replacements rather than a line-number diff, because line offsets
in a hand-committed Markdown file are not stable enough to patch safely.

---

## §01 Document control

**Replace** the `Doc version / status` row value with:
`1.1 · APPROVED — READY TO BUILD. Issued 2026-11-13, amended 2026-11-13.`

**Add row:**
| Process contract | `AGENTS.md` owns process/tooling. `STACK.md` owns dependencies. `docs/CODING-STANDARDS.md` owns code rules. `GLOSSARY.md` owns vocabulary. |

---

## §13 Testing & verification strategy

**Replace the L1–L4 table rows for L1 and L4 with:**

| L1 Unit | `dart test`, `go test` | Core: public API only (`FugueDoc`, `OpStore`). Relay: black-box WS/HTTP + DB rows. App: bloc + domain/data. **No widget tests.** | Every PR |
| L4 Manual | Two physical Android phones | Airplane-mode partition, arbitrary reconnect order, kill/reopen. Recorded in `docs/e2e.md`. | M3 exit + demo video |

**Replace the "Property catalog" intro sentence with:**
Assertions use `package:checks`. Properties target the public API only, so swapping the
engine implementation requires no test edits — demonstrated at M2 when the stub is replaced.

**Add new subsection after "Deterministic simulator spec":**

### Sabotage suite (replaces coverage as the quality gate)

Eight deliberately wrong merge variants live in `scripts/sabotage.manifest`. Each maps to an
invariant. `just sabotage` applies one variant at a time and runs the property + simulator
suite; the suite **must fail**. A surviving mutant means the tests are too weak and fails the
build. A `sed` that matches nothing is reported `BROKEN` and also fails — the manifest cannot
go stale silently.

| Mutant | Invariant |
| --- | --- |
| reverse-tiebreak | CR-05 |
| no-causal-buffer | CR-04 |
| non-idempotent-apply | CR-03 |
| physical-tombstone-delete | CR-06 |
| index-instead-of-nodeid | CR-01 |
| ignore-left-origin | CR-05 |
| drop-opid-dedup | CR-03 |
| swap-traversal-order | CR-01 |

All entries are armed during M1. From M1 exit, nightly runs `just sabotage --strict`.

**Replace the coverage paragraph with:**
Coverage is a hygiene ratchet, not a headline gate: `weft_core` coverage may never fall below
the baseline locked at end of M1. Coverage measures lines executed, not assertions made, and
is a weak correctness signal for a CRDT. The sabotage suite is the real gate.

**Replace the benchmark paragraph with:**
Absolute NFR budgets are verified locally on the Dell under fixed conditions (plugged in,
same governor, warmup). CI benchmark numbers are informational. Nightly local runs append to
`docs/BENCHMARKS.md`; a ticket opens only after **two consecutive** regressions >10% against
the median of the last five runs.

---

## §14 Operations & CI/CD

**Add to the topology table:**
| Local gates | lefthook | pre-commit (<10 s): format, analyze, secret scan · commit-msg: Conventional Commits · pre-push: `just ci` |
| Command entry point | just | Every gate is `just <recipe>`; local and CI cannot drift |
| Drift gate | `just drift` | STACK vs manifests · doc recipes vs justfile · allowlisted skills on disk · ADR references · requirement IDs |
| Container image | `gcr.io/distroless/static-debian12` | No shell in the relay image |

**Add to the M0 exit criteria:** Android build must satisfy AGP ≥ 8.12.1, Gradle ≥ 8.13, Java 17.

---

## §15 Schedule & milestones

**Replace the M0 row dates** `Nov 12–18` **with** `Nov 13–20`.

**Add note under the milestone table:**
The full toolchain upgrade (Q60) precedes repo creation and consumes 1–2 h. M0 therefore
targets Nov 19 with buffer to Nov 20. The hard wall of 2027-01-10 is unchanged; the buffer
absorbs the slip.

---

## §17 Process & AI delegation

**Replace PR-03 with:**
| PR-03 | **Defendability gate:** every PR touching `packages/weft_core` carries five lines written by Fady, in his own words, no file open — what changed, why it is correct, which invariant it protects, which test proves it, what could still break. The agent prompts for this text and must never write it. |

**Replace PR-06 with:**
| PR-06 | Skill routing per `opencode.jsonc`: default-deny, explicit allow/ask tiers. Conflicting skills are denied, not deleted. spec-kit, Artemis and EGM are forbidden in this repo. |

**Add rows:**
| PR-09 | Test-strength gate: the sabotage suite must kill every armed mutant. Coverage is a ratchet only. |
| PR-10 | Model-agnostic config: no `model` key in repo config. Capability floor in `AGENTS.md`; each core PR records the model used. |
| PR-11 | Dependency policy: `STACK.md` is the contract. Listed optional packages need a STACK update; anything unlisted needs an ADR. |

**Replace the "Must be Fady's" list item** "Definition of 'correct'" **with:**
Definition of "correct" — the invariants themselves, authored before any property test.

---

## §18 Deliverables & definition of done

**Add to the required docs list:**
`STACK.md`, `GLOSSARY.md`, `docs/CODING-STANDARDS.md`, `docs/adr/README.md`.

**Add checklist items:**

- [ ] `just drift` green — docs and code agree mechanically.
- [ ] Sabotage suite armed with all eight mutants; every one killed.
- [ ] `opencode.jsonc` committed; skill allowlist matches vendored skills on disk.

---

## §19 Agent operating contract

**Replace the deltas table row** "Core-first phase order" **with:**
| Core-first phase order | Walking skeleton first (M0), stub engine satisfies CR-01/02/03; P-04/05/06 skipped until M1. |

**Add to Operating rules:**
12. `AGENTS.md` is the process source of truth; this PRD is the product source of truth.
13. Never invoke spec-kit, Artemis, or EGM in this repo.
14. Never write Fady's five-line defendability text.
15. Never add a dependency absent from `STACK.md` without an ADR.

---

## New ADRs

0012 connectivity authority · 0013 dependency manifest · 0014 skill routing ·
0015 sabotage suite · 0016 model-agnostic config. Index in `docs/adr/README.md`.
