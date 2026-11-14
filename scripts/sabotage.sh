#!/usr/bin/env bash
# Sabotage suite (ADR-0015): break the merge on purpose; the tests must notice.
# A surviving mutant means the test suite is too weak, and that fails the build.
#   default   run armed mutants; report pending; pass if none armed yet
#   --strict  also fail if any mutant is pending or none are armed (from M1 exit)
set -euo pipefail

CORE=packages/weft_core
MANIFEST=scripts/sabotage.manifest
STRICT=0
[[ "${1:-}" == "--strict" ]] && STRICT=1

[[ -d "$CORE/lib" ]] || {
  echo "sabotage: $CORE/lib not found"
  exit 1
}
[[ -f "$MANIFEST" ]] || {
  echo "sabotage: manifest missing"
  exit 1
}

backup="$(mktemp -d)"
cp -a "$CORE/lib" "$backup/lib"
reset_lib() {
  rm -rf "${CORE:?}/lib"
  cp -a "$backup/lib" "$CORE/lib"
}
# Invoked by the EXIT trap below, never called directly.
# shellcheck disable=SC2329
cleanup() {
  reset_lib
  rm -rf "$backup"
}
trap cleanup EXIT

armed=0 pending=0 killed=0 survived=0 broken=0
logs="$(mktemp -d)"

while IFS='|' read -r id status file expr inv _note; do
  case "${id:-}" in '' | \#*) continue ;; esac
  if [[ "$status" != "armed" ]]; then
    pending=$((pending + 1))
    printf 'PENDING  %-26s %s\n' "$id" "$inv"
    continue
  fi
  armed=$((armed + 1))
  reset_lib
  target="$CORE/$file"
  if [[ ! -f "$target" ]]; then
    printf 'BROKEN   %-26s missing file %s\n' "$id" "$file"
    broken=$((broken + 1))
    continue
  fi
  before="$(sha256sum "$target" | cut -d' ' -f1)"
  sed -i "$expr" "$target"
  after="$(sha256sum "$target" | cut -d' ' -f1)"
  if [[ "$before" == "$after" ]]; then
    printf 'BROKEN   %-26s sed matched nothing — manifest is stale\n' "$id"
    broken=$((broken + 1))
    continue
  fi
  if (cd "$CORE" && WEFT_PROPERTY_CASES=200 WEFT_SIM_SEEDS=200 \
    dart test --exclude-tags=benchmark) >"$logs/$id.log" 2>&1; then
    printf 'SURVIVED %-26s %s — suite too weak\n' "$id" "$inv"
    survived=$((survived + 1))
  else
    printf 'killed   %-26s %s\n' "$id" "$inv"
    killed=$((killed + 1))
  fi
done <"$MANIFEST"

reset_lib
echo "---"
echo "armed=$armed killed=$killed survived=$survived broken=$broken pending=$pending"
echo "logs: $logs"

fail=0
((survived > 0)) && fail=1
((broken > 0)) && fail=1
if ((armed == 0)); then
  if ((STRICT == 1)); then
    echo "sabotage: no armed mutants (strict)"
    fail=1
  else echo "sabotage: not armed yet — arm all entries during M1"; fi
fi
((STRICT == 1 && pending > 0)) && {
  echo "sabotage: pending mutants (strict)"
  fail=1
}
exit $fail
