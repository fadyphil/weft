#!/usr/bin/env bash
# Pinned, verified toolchain bootstrap.
#   resolve      install current upstream releases, record exact versions
#   install      reinstall exactly the pinned versions (fails closed)
#   doctor       report presence and pinned-vs-installed
#   pin-actions  replace GitHub Action version tags with commit SHAs
#
# Design: prebuilt binaries wherever upstream publishes them (no Go dependency
# graph to break against a frozen toolchain). go install only for x/ tools.
set -euo pipefail

BIN="${HOME}/.local/bin"
ENV_FILE="$(dirname "$0")/tool-versions.env"
API="https://api.github.com/repos"
mkdir -p "$BIN"

# name|go package path — source-only tools
GO_TOOLS=(
  "govulncheck|golang.org/x/vuln/cmd/govulncheck"
)
# name|owner/repo|requirement
BIN_TOOLS=(
  "just|casey/just|required"
  "lefthook|evilmartians/lefthook|required"
  "golangci-lint|golangci/golangci-lint|required"
  "git-cliff|orhun/git-cliff|required"
  "gitleaks|zricethezav/gitleaks|required"
  "shfmt|mvdan/sh|required"
  "yq|mikefarah/yq|required"
  "actionlint|rhysd/actionlint|required"
  "age|FiloSottile/age|optional"
  "rclone|rclone/rclone|optional"
)

die() {
  echo "ERROR: $*" >&2
  exit 1
}
for t in curl jq go tar; do command -v "$t" >/dev/null || die "$t is required"; done

go_version_of() { go version -m "$1" 2>/dev/null | awk '$1=="mod"{print $3; exit}'; }

pick_asset() { # release-json -> url, prefer tar.gz > zip > raw
  local j="$1" urls
  urls="$(jq -r '.assets[]
    | select(.name | test("sha256|sha512|checksum|\\.asc$|\\.sig$|\\.pem$|\\.json$|\\.apk$|\\.deb$|\\.rpm$";"i") | not)
    | .browser_download_url' <<<"$j" |
    grep -Ei 'linux' | grep -Ei 'amd64|x86_64|x64' |
    grep -Eiv 'arm|386|i386|riscv|ppc|s390|mips|loong' || true)"
  [[ -n "$urls" ]] || return 1
  grep -E '\.tar\.gz$|\.tgz$' <<<"$urls" | head -1 && return 0
  grep -E '\.zip$' <<<"$urls" | head -1 && return 0
  head -1 <<<"$urls"
}

verify_digest() { # release-json asset-name file
  local want
  want="$(jq -r --arg n "$2" '.assets[] | select(.name==$n) | .digest // empty' <<<"$1")"
  if [[ "$want" == sha256:* ]]; then
    (cd "$(dirname "$3")" && echo "${want#sha256:}  $2" | sha256sum -c -) && return 0
    die "sha256 mismatch for $2"
  fi
  local sum_url sum_name
  sum_url="$(jq -r '.assets[].browser_download_url' <<<"$1" |
    grep -Ei 'checksums|sha256sums|\.sha256$|\.sha512$' | head -1 || true)"
  [[ -n "$sum_url" ]] || die "no digest or checksum published for $2 — verify manually, record hash in an ADR"
  sum_name="$(basename "$sum_url")"
  curl -fsSL -o "$(dirname "$3")/$sum_name" "$sum_url"
  want="$(grep -F "$2" "$(dirname "$3")/$sum_name" | awk '{print $1}' | head -1)"
  [[ -n "$want" ]] || want="$(awk 'NF==1{print $1; exit}' "$(dirname "$3")/$sum_name")"
  case "${#want}" in
  64) (cd "$(dirname "$3")" && echo "$want  $2" | sha256sum -c -) ;;
  128) (cd "$(dirname "$3")" && echo "$want  $2" | sha512sum -c -) ;;
  *) die "unrecognised checksum for $2" ;;
  esac
}

bin_install() { # name repo tag requirement
  local name="$1" repo="$2" tag="$3" req="$4" j url asset tmp found
  j="$(curl -fsSL "$API/$repo/releases/tags/$tag")" || {
    [[ "$req" == optional ]] && {
      echo "SKIP $name (no release $tag)"
      return 0
    }
    die "cannot read $repo@$tag"
  }
  url="$(pick_asset "$j")" || {
    [[ "$req" == optional ]] && {
      echo "SKIP $name (no linux amd64 asset)"
      return 0
    }
    die "no linux amd64 asset for $repo@$tag"
  }
  asset="$(basename "$url")"
  tmp="$(mktemp -d)"
  echo "==> $name $tag ($asset)"
  curl -fsSL -o "$tmp/$asset" "$url"
  verify_digest "$j" "$asset" "$tmp/$asset"
  case "$asset" in
  *.tar.gz | *.tgz) tar -xzf "$tmp/$asset" -C "$tmp" ;;
  *.tar.xz) tar -xJf "$tmp/$asset" -C "$tmp" ;;
  *.zip)
    command -v unzip >/dev/null || die "unzip needed for $asset"
    unzip -q "$tmp/$asset" -d "$tmp"
    ;;
  *.gz) gunzip -c "$tmp/$asset" >"$tmp/$name" ;;
  *) cp "$tmp/$asset" "$tmp/$name" ;;
  esac
  found="$(find "$tmp" -type f -name "$name" | head -1)"
  [[ -n "$found" ]] || found="$(find "$tmp" -type f -perm -u+x ! -name "$asset" | head -1)"
  [[ -n "$found" ]] || die "binary '$name' not found inside $asset"
  install -m755 "$found" "$BIN/$name"
  rm -rf "$tmp"
}

resolve() {
  local only=("$@") failures=()
  [[ -f "$ENV_FILE" ]] || : >"$ENV_FILE"
  ((${#only[@]} == 0)) && : >"$ENV_FILE"

  in_only() {
    ((${#only[@]} == 0)) && return 0
    local n
    for n in "${only[@]}"; do [[ "$n" == "$1" ]] && return 0; done
    return 1
  }
  record() {
    sed -i "/^$1=/d" "$ENV_FILE"
    echo "$1=$2" >>"$ENV_FILE"
  }

  for e in "${GO_TOOLS[@]}"; do
    local name="${e%%|*}" pkg="${e#*|}" ver
    in_only "$name" || continue
    echo "==> $name (go install $pkg@latest)"
    if GOBIN="$BIN" go install "$pkg@latest" &&
      ver="$(go_version_of "$BIN/$name")" && [[ -n "$ver" ]]; then
      record "$name" "$ver"
    else
      echo "FAILED: $name — go install $pkg"
      failures+=("$name")
    fi
  done

  for e in "${BIN_TOOLS[@]}"; do
    IFS='|' read -r name repo req <<<"$e"
    in_only "$name" || continue
    echo "==> $name (resolving $repo)"
    local tag
    tag="$(curl -fsSL "$API/$repo/releases/latest" 2>/dev/null | jq -r '.tag_name // empty' || true)"
    if [[ -z "$tag" ]]; then
      echo "FAILED: $name — no release at $API/$repo/releases/latest (check owner/repo)"
      failures+=("$name")
      continue
    fi
    bin_install "$name" "$repo" "$tag" "$req"
    record "$name" "${tag#v}"
  done

  echo
  echo "--- $ENV_FILE ---"
  cat "$ENV_FILE"
  if ((${#failures[@]})); then
    echo
    echo "FAILED: ${failures[*]}"
    return 1
  fi
  echo
  echo "All resolved. Review, commit, then: just bootstrap"
}

install_pinned() {
  [[ -f "$ENV_FILE" ]] || die "run ./scripts/bootstrap.sh resolve first"
  grep -q UNPINNED "$ENV_FILE" && die "unpinned entries in $ENV_FILE"
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  for e in "${GO_TOOLS[@]}"; do
    local name="${e%%|*}" pkg="${e#*|}"
    local ver="${!name:-}"
    [[ -n "$ver" ]] || die "$name missing from $ENV_FILE"
    echo "==> go install $pkg@$ver"
    GOBIN="$BIN" go install "$pkg@$ver"
  done
  for e in "${BIN_TOOLS[@]}"; do
    IFS='|' read -r name repo req <<<"$e"
    local ver="${!name:-}" tag=""
    [[ -n "$ver" ]] || {
      [[ "$req" == optional ]] && continue
      die "$name missing from $ENV_FILE"
    }
    for t in "v$ver" "$ver"; do
      curl -fsSL -o /dev/null "$API/$repo/releases/tags/$t" && {
        tag="$t"
        break
      }
    done
    [[ -n "$tag" ]] || {
      [[ "$req" == optional ]] && {
        echo "SKIP $name $ver"
        continue
      }
      die "no release $ver for $repo"
    }
    bin_install "$name" "$repo" "$tag" "$req"
  done
  doctor
}

doctor() {
  printf '%-16s %-14s %s\n' TOOL PINNED STATUS
  for t in just lefthook golangci-lint git-cliff gitleaks govulncheck shfmt shellcheck yq actionlint age rclone scrcpy psql; do
    local pinned="-"
    [[ -f "$ENV_FILE" ]] && pinned="$(grep -E "^$t=" "$ENV_FILE" | cut -d= -f2 || true)"
    if command -v "$t" >/dev/null; then
      printf '%-16s %-14s %s\n' "$t" "${pinned:--}" ok
    else printf '%-16s %-14s %s\n' "$t" "${pinned:--}" MISSING; fi
  done
  echo "---"
  dart --version
  go version
  flutter --version | head -1
  case ":$PATH:" in *":$BIN:"*) ;; *) echo "WARNING: $BIN not on PATH" ;; esac
}

pin_actions() {
  command -v gh >/dev/null || die "gh required"
  for f in .github/workflows/*.yml; do
    grep -oE 'uses: [^@]+@v[0-9]+' "$f" | sort -u | while read -r _ ref; do
      local repo="${ref%@*}" tag="${ref##*@}" sha
      sha="$(gh api "repos/$repo/git/ref/tags/$tag" --jq .object.sha 2>/dev/null)" || continue
      sed -i "s|uses: $repo@$tag|uses: $repo@$sha # $tag|g" "$f"
    done
  done
  echo "Actions pinned to SHAs. Review the diff before committing."
}

case "${1:-}" in
resolve)
  shift
  resolve "$@"
  ;;
install) install_pinned ;;
doctor) doctor ;;
pin-actions) pin_actions ;;
*) die "usage: $0 {resolve|install|doctor|pin-actions}" ;;
esac
