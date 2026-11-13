#!/usr/bin/env bash
# Mechanical doc-vs-code drift gate (Q67). Semantic drift stays a human task.
# Fixes vs first version: per-tier dep comparison, go.mod indirect exclusion,
# doc scope excludes vendored skills, planned ADRs accepted.
set -euo pipefail
fail=0
err() { echo "DRIFT: $*"; fail=1; }

[[ -f STACK.md ]] || { echo "DRIFT: STACK.md missing"; exit 1; }

DOC_PATHS=(README.md PRD.md AGENTS.md STACK.md GLOSSARY.md docs)
existing=()
for p in "${DOC_PATHS[@]}"; do [[ -e "$p" ]] && existing+=("$p"); done

block() {
  sed -n "/<!-- drift:begin $1 -->/,/<!-- drift:end -->/p" STACK.md \
    | grep -vE '<!--|^[[:space:]]*$' | sed 's/^[[:space:]]*//' | sort -u
}

pub_keys() { yq -r ".${2} // {} | keys | .[]" "$1" 2>/dev/null \
  | grep -vE '^(flutter|flutter_test|integration_test)$' | sort -u; }

gomod_direct() {
  awk '
    /^require \(/ {inb=1; next}
    inb && /^\)/ {inb=0; next}
    inb && $0 !~ /\/\/ indirect/ && NF>=2 {print $1}
    /^require [^()]/ && $0 !~ /\/\/ indirect/ {print $2}
  ' relay/go.mod | sort -u
}

compare() { # tier label actual
  if ! diff <(block "$1") <(printf '%s\n' "$3" | grep -v '^$' | sort -u) >/dev/null; then
    err "$1 differs from $2"
    diff <(block "$1") <(printf '%s\n' "$3" | grep -v '^$' | sort -u) | sed 's/^/    /' || true
  fi
}

for spec in "core-runtime:packages/weft_core/pubspec.yaml:dependencies" \
            "core-dev:packages/weft_core/pubspec.yaml:dev_dependencies" \
            "app-runtime:apps/weft_app/pubspec.yaml:dependencies" \
            "app-dev:apps/weft_app/pubspec.yaml:dev_dependencies"; do
  IFS=: read -r tier file section <<<"$spec"
  [[ -f "$file" ]] || { err "$file missing"; continue; }
  compare "$tier" "$file" "$(pub_keys "$file" "$section")"
done

if [[ -f relay/go.mod ]]; then
  compare relay relay/go.mod "$(gomod_direct)"
fi

# just recipes referenced in our docs must exist
if command -v just >/dev/null; then
  recipes="$(just --summary | tr ' ' '\n' | sort -u)"
  while read -r r; do
    [[ -n "$r" ]] || continue
    grep -qx "$r" <<<"$recipes" || err "docs reference missing recipe: just $r"
  done < <(grep -rhoE '\bjust [a-z][a-z0-9-]+' "${existing[@]}" 2>/dev/null | awk '{print $2}' | sort -u)
fi

# allowlisted skills must be vendored
if [[ ! -d .agents/skills ]]; then
  err ".agents/skills not vendored"
else
  while read -r s; do
    [[ -n "$s" ]] || continue
    [[ -f ".agents/skills/$s/SKILL.md" ]] || err "allowlisted skill missing: $s"
  done < <(grep -oE '"action": "skill", "resource": "[^"]+", "effect": "(allow|ask)"' opencode.jsonc \
            | sed -E 's/.*"resource": "([^"]+)".*/\1/' | grep -v '\*' | sort -u)
fi

# referenced ADRs must exist or be listed as planned
while read -r a; do
  [[ -n "$a" ]] || continue
  n="${a#ADR-}"
  if ! ls docs/adr/"$n"-*.md >/dev/null 2>&1; then
    grep -qE "^\| *$n *\|" docs/adr/README.md 2>/dev/null || err "missing $a (no file, not planned)"
  fi
done < <(grep -rhoE 'ADR-[0-9]{4}' "${existing[@]}" 2>/dev/null | sort -u)

# requirement IDs cited in TESTING.md must exist in PRD.md
if [[ -f docs/TESTING.md && -f PRD.md ]]; then
  while read -r id; do
    [[ -n "$id" ]] || continue
    grep -q "$id" PRD.md || err "TESTING.md cites unknown requirement $id"
  done < <(grep -ohE '\b(FR|CR|NFR|OR|PR|DR)-[0-9]{2}\b' docs/TESTING.md | sort -u)
fi

(( fail == 0 )) && echo "drift: ok"
exit $fail