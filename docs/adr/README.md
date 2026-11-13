# Architecture Decision Records

MADR-style. Status: `proposed` → `accepted` → `superseded`.
Create with `just adr "title"`.

`just drift` accepts a reference if the ADR file exists **or** it is listed as planned below.
At each milestone's `just release-check`, that milestone's ADRs must be `accepted`.

## Planned

| ADR | Decision | Milestone | Status |
|---|---|---|---|
| 0001 | Pure Dart core, not Rust + FFI | M0 | planned |
| 0002 | Tree-Fugue first, List-Fugue stretch | M1 | planned |
| 0003 | Dumb relay + containment argument | M0 | planned |
| 0004 | Append-only log + snapshot persistence | M2 | planned |
| 0005 | Room-code/QR pairing, no accounts | M2 | planned |
| 0006 | Cursor-based delivery protocol | M0 | planned |
| 0007 | Hand-built deterministic simulator | M1 | planned |
| 0008 | Free-tier ops topology (Render + Neon) | M0 | planned |
| 0009 | Cut order + Dec 9 Fugue checkpoint | M0 | planned |
| 0010 | RGA fallback — only if the checkpoint fails | M1 | conditional |
| 0011 | Restore drill result | M4 | planned |
| 0012 | Connectivity is a hint; the socket is authority | M0 | planned |
| 0013 | Dependency manifest and tier policy | M0 | planned |
| 0014 | Skill routing: default-deny + allowlist | M0 | planned |
| 0015 | Sabotage suite replaces coverage-as-gate | M1 | planned |
| 0016 | Model-agnostic agent config + capability floor | M0 | planned |