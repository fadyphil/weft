#!/usr/bin/env bash
# Run a command inside a subtree that may not exist yet.
#
# M0 assembles the repo bottom-up: the relay (#3), the core (#2), and the app (#5)
# arrive as separate branches. A gate that blindly `cd`s into an absent directory
# fails for a reason that is already tracked by an open ticket, and that failure is
# indistinguishable from a real one. So the absence is reported and skipped — loudly,
# with the path named, never silently.
#
# Skips are meant to disappear on their own: each subtree stops skipping the moment
# it exists. To make absence a failure again, set WEFT_STRICT_TREE=1. Issue #9 flips
# that on once the walking skeleton is complete.
#
# Usage: at.sh <dir> <command> [args...]
set -euo pipefail

if (($# < 2)); then
  echo "usage: at.sh <dir> <command> [args...]" >&2
  exit 2
fi

dir="$1"
shift

if [[ -d "$dir" ]]; then
  cd "$dir"
  exec "$@"
fi

if [[ "${WEFT_STRICT_TREE:-0}" == "1" ]]; then
  echo "FAIL: $dir absent and WEFT_STRICT_TREE=1" >&2
  exit 1
fi

echo "skip: $dir absent — nothing to run"
