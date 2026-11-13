#!/usr/bin/env bash
# Pinned, verified toolchain bootstrap.
#   resolve      write upstream latest versions into scripts/tool-versions.env
#   install      install exactly the pinned versions (fails closed)
#   doctor       report installed vs pinned
#   pin-actions  replace GitHub Action version tags with commit SHAs
set -euo pipefail

BIN="${HOME}/.local/bin"
ENV_FILE="$(dirname "$0")/tool-versions.env"
mkdir -p "$BIN"

# name -> install method
GO_TOOLS=(
  "lefthook:github.com/evilmartians/lefthook"
  "gitleaks:github.com/zricethezav/gitleaks/v8"
  "govulncheck:golang.org/x/vuln/cmd/govulncheck"
  "shfmt:mvdan.cc/sh/v3/cmd/shfmt"
  "yq:github.com/mikefarah/yq/v4"
  "age:filippo.io/age/cmd/age"
  "actionlint:github.com/rhysd/actionlint/cmd/actionlint"
)
TARBALL_REPOS=("just:casey/just" "git-cliff:orhun/git-cliff" "golangci-lint:golangci/golangci-lint")
APT_TOOLS=(shellcheck scrcpy postgresql-client)

die() { echo "ERROR: $*" >&2; exit 1; }

resolve() {
  : >"$ENV_FILE"
  for entry in "${GO_TOOLS[@]}"; do
    name="${entry%%:*}"; mod="${entry#*:}"
    ver="$(go list -m -versions "$mod" 2>/dev/null | awk '{print $NF}')"
    [[ -n "$ver" ]] || ver="UNPINNED"
    echo "${name}=${ver}" >>"$ENV_FILE"
  done
  for entry in "${TARBALL_REPOS[@]}"; do
    name="${entry%%:*}"; repo="${entry#*:}"
    ver="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
      | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')" || ver="UNPINNED"
    echo "${name}=${ver}" >>"$ENV_FILE"
  done
  echo "Wrote $ENV_FILE — review it, commit it, then run: just bootstrap"
  cat "$ENV_FILE"
}

verify() { # file repo version
  local file="$1" repo="$2" ver="$3" base sum
  base="https://github.com/${repo}/releases/download"
  for tag in "v${ver}" "${ver}"; do
    for candidate in SHA256SUMS checksums.txt \
      "${repo##*/}-${ver}-checksums.txt" "${file}.sha256" "${file}.sha512"; do
      if sum="$(curl -fsSL "${base}/${tag}/${candidate}" 2>/dev/null)"; then
        local want
        want="$(printf '%s\n' "$sum" | grep -F "$file" | awk '{print $1}' | head -1)"
        [[ -n "$want" ]] || continue
        case "${#want}" in
          64) echo "${want}  ${file}" | sha256sum -c - && return 0 ;;
          128) echo "${want}  ${file}" | sha512sum -c - && return 0 ;;
        esac
      fi
    done
  done
  die "no upstream checksum found for ${file}. Verify manually, then record the hash in an ADR."
}

install() {
  [[ -f "$ENV_FILE" ]] || die "run: just resolve-tools (then review + commit $ENV_FILE)"
  grep -q UNPINNED "$ENV_FILE" && die "unpinned versions in $ENV_FILE"
  # shellcheck disable=SC1090
  source "$ENV_FILE"

  for entry in "${GO_TOOLS[@]}"; do
    name="${entry%%:*}"; mod="${entry#*:}"
    ver="${!name}"
    echo "==> go install ${mod}@${ver}"
    GOBIN="$BIN" go install "${mod}@${ver}"
  done

  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  for entry in "${TARBALL_REPOS[@]}"; do
    name="${entry%%:*}"; repo="${entry#*:}"; ver="${!name}"
    asset="${name}-${ver}-linux-amd64.tar.gz"
    [[ "$name" == "just" ]] && asset="just-${ver}-x86_64-unknown-linux-musl.tar.gz"
    echo "==> ${name} ${ver}"
    curl -fsSL -o "${tmp}/${asset}" \
      "https://github.com/${repo}/releases/download/v${ver}/${asset}" \
      || curl -fsSL -o "${tmp}/${asset}" \
        "https://github.com/${repo}/releases/download/${ver}/${asset}"
    (cd "$tmp" && verify "$asset" "$repo" "$ver")
    tar -xzf "${tmp}/${asset}" -C "$tmp"
    find "$tmp" -maxdepth 2 -type f -name "$name" -exec install -m755 {} "$BIN/" \;
  done

  echo "==> apt tools (human may be prompted for sudo)"
  command -v shellcheck >/dev/null || echo "install manually: ${APT_TOOLS[*]}"
  doctor
}

doctor() {
  printf '%-16s %s\n' TOOL STATUS
  for t in just lefthook golangci-lint git-cliff gitleaks govulncheck shfmt shellcheck yq age actionlint rclone scrcpy psql; do
    if command -v "$t" >/dev/null; then printf '%-16s %s\n' "$t" "ok"; else printf '%-16s %s\n' "$t" "MISSING"; fi
  done
  echo "---"
  dart --version; go version; flutter --version | head -1
}

pin_actions() {
  for f in .github/workflows/*.yml; do
    grep -oE 'uses: [^@]+@v[0-9]+' "$f" | sort -u | while read -r _ ref; do
      repo="${ref%@*}"; tag="${ref##*@}"
      sha="$(gh api "repos/${repo}/git/ref/tags/${tag}" --jq .object.sha 2>/dev/null)" || continue
      sed -i "s|uses: ${repo}@${tag}|uses: ${repo}@${sha} # ${tag}|g" "$f"
    done
  done
  echo "Actions pinned to SHAs. Review the diff before committing."
}

case "${1:-}" in
  resolve) resolve ;;
  install) install ;;
  doctor) doctor ;;
  pin-actions) pin_actions ;;
  *) die "usage: $0 {resolve|install|doctor|pin-actions}" ;;
esac