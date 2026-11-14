#!/usr/bin/env bash
# Enforces PRD §08 boundaries. A violation is a build failure, not a warning.
#
# A rule can only be enforced over code that exists. While a subtree is absent its
# rules are reported as skipped, by name — an `architecture: ok` that has checked
# nothing must never be able to pass for a clean scan. WEFT_STRICT_TREE=1 turns a
# skip into a failure, for when the tree is complete.
set -euo pipefail
fail=0
skipped=()

check() { # description pattern paths...
  local desc="$1" pat="$2"
  shift 2
  local present=() p
  for p in "$@"; do [[ -e "$p" ]] && present+=("$p"); done
  if ((${#present[@]} == 0)); then
    if [[ "${WEFT_STRICT_TREE:-0}" == "1" ]]; then
      echo "FAIL: $desc — $* absent and WEFT_STRICT_TREE=1"
      fail=1
    else
      skipped+=("$desc — $*")
    fi
    return 0
  fi
  if grep -rInE "$pat" "${present[@]}" 2>/dev/null; then
    echo "FAIL: $desc"
    fail=1
  fi
}

check "weft_core must not import Flutter or dart:ui" \
  'package:flutter/|dart:ui' packages/weft_core/lib
check "weft_core must not import network or app packages" \
  'package:(dio|http|web_socket_channel|connectivity_plus|flutter_bloc|get_it)/' packages/weft_core/lib
check "weft_core must not use codegen" \
  "part '.*\.(g|freezed)\.dart'" packages/weft_core/lib
check "app must not import core internals" \
  'package:weft_core/src/' apps/weft_app/lib
check "app must not contain merge logic" \
  'leftOrigin|tieBreak|compareNodeIds|class .*Merge' apps/weft_app/lib
check "relay must not contain CRDT semantics" \
  'fugue|leftOrigin|left_origin|tieBreak|NodeID' relay --include='*.go'

if ((fail == 0)); then
  if ((${#skipped[@]} > 0)); then
    for s in "${skipped[@]}"; do echo "skip: $s — subtree absent"; done
    echo "architecture: ok (${#skipped[@]} check(s) skipped — see above)"
  else
    echo "architecture: ok"
  fi
fi
exit $fail
