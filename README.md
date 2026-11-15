# Weft

A collaborative plain-text editor where devices edit **offline** and always **converge** —
powered by a hand-built Tree-Fugue CRDT in pure Dart, a Flutter client, and a deliberately
dumb Go relay.

**Status: M0 — walking skeleton. Not yet usable.**

The editor is the demo surface. The engine is the project.

## Documents

| File | Purpose |
| --- | --- |
| [PRD.md](PRD.md) | Product requirements — scope, invariants, milestones |
| [AGENTS.md](AGENTS.md) | Agent operating contract |
| [STACK.md](STACK.md) | Dependency contract |
| [GLOSSARY.md](GLOSSARY.md) | Shared vocabulary |
| [docs/CODING-STANDARDS.md](docs/CODING-STANDARDS.md) | Code rules |
| [docs/core/](docs/core/) | Kernel rules, order decisions, diagnosis protocol, goldens |
| [docs/adr/](docs/adr/) | Architecture decision records |

## Development

```bash
./scripts/bootstrap.sh install   # pinned, checksum-verified toolchain
just hooks                       # install local gates
just --list                      # available commands
```

## License

MIT — see [LICENSE](LICENSE).
