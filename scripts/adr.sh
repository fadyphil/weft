#!/usr/bin/env bash
set -euo pipefail
title="${1:?usage: just adr \"title\"}"
dir=docs/adr; mkdir -p "$dir"
last="$(ls "$dir" 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1 || true)"
n="$(printf '%04d' "$(( ${last:-0} + 1 ))")"
slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"
file="$dir/$n-$slug.md"
cat >"$file" <<EOF
# ADR-$n: $title

- Status: proposed
- Date: $(date -u +%Y-%m-%d)
- Deciders: Fady Philip

## Context
What forced this decision? Which constraint or requirement (PRD ID) applies?

## Decision
What we chose, in one paragraph.

## Alternatives considered
- Option — why rejected.

## Consequences
What becomes easier, what becomes harder, what we now owe.

## Evidence
Tests, benchmarks, or links that justify this.
EOF
{ echo "# Architecture Decision Records"; echo; \
  for f in "$dir"/[0-9]*.md; do echo "- [$(basename "$f" .md)]($f)"; done; } >"$dir/README.md"
echo "created $file"