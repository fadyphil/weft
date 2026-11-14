#!/usr/bin/env bash
# Run a command in a code subtree that may not exist yet.
#
# M0 assembles the repo bottom-up: the relay (#3), the core (#2), and the app (#5)
# arrive as separate branches. A gate that blindly `cd`s into an absent subtree
# fails for a reason that is already tracked by an open ticket, and that failure is
# indistinguishable from a real one. So the absence is reported and skipped — loudly,
# with the path named, never silently.
#
# A skip protects nothing: it disappears the moment the subtree exists. To forbid
# skipping entirely — when the tree is complete — set WEFT_STRICT_TREE=1.
#
# Usage:
#   in-subtree.sh <subtree> <command> [args...]          run inside the subtree
#   in-subtree.sh --root <subtree> <command> [args...]   check it, stay in repo root
#
# --root is for scripts that resolve their own repo-relative paths and must not be
# moved, such as sabotage.sh.
set -euo pipefail

root=0
if [[ "${1:-}" == "--root" ]]; then
  root=1
  shift
fi

if (($# < 2)); then
  echo "usage: in-subtree.sh [--root] <subtree> <command> [args...]" >&2
  exit 2
fi

subtree="$1"
shift

absent() {
  if [[ "${WEFT_STRICT_TREE:-0}" == "1" ]]; then
    echo "FAIL: $subtree absent and WEFT_STRICT_TREE=1" >&2
    exit 1
  fi
  echo "skip: $subtree absent — nothing to run"
  exit 0
}

[[ -d "$subtree" ]] || absent

((root == 1)) && exec "$@"

cd "$subtree"
exec "$@"
