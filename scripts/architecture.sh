#!/usr/bin/env bash
# Enforces PRD §08 boundaries. A violation is a build failure, not a warning.
set -euo pipefail
fail=0

check() { # description pattern paths...
  local desc="$1" pat="$2"
  shift 2
  if grep -rInE "$pat" "$@" 2>/dev/null; then
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

[[ $fail -eq 0 ]] && echo "architecture: ok"
exit $fail
