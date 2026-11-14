#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import pathlib
user_invoked = """ask-matt grill-with-docs triage improve-codebase-architecture
setup-matt-pocock-skills to-spec to-tickets implement retro grill-me handoff
teach to-questionnaire wait-what""".split()
for name in user_invoked:
    p = pathlib.Path(".agents/skills") / name / "SKILL.md"
    if not p.exists():
        print(f"MISSING {name}"); continue
    t = p.read_text()
    if not t.startswith("---"):
        print(f"NO FRONTMATTER {name}"); continue
    end = t.index("\n---", 3)
    fm = t[3:end]
    if "opencode/autoinvoke" in fm:
        print(f"already set: {name}"); continue
    if "\nmetadata:" in fm:
        fm = fm.replace("\nmetadata:", "\nmetadata:\n  opencode/autoinvoke: false", 1)
    else:
        fm = fm.rstrip() + "\nmetadata:\n  opencode/autoinvoke: false\n"
    p.write_text("---" + fm + t[end:])
    print(f"patched: {name}")
PY
