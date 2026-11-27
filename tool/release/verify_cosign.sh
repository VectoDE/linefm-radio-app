#!/usr/bin/env bash
# Verifies the cosign bundles (*.sigstore.json) of a LINEFM release with one or
# more pinned cosign versions, so a release is checked with cosign 2.x and 3.x.
#
#   tool/release/verify_cosign.sh fetch  <version> <cache-dir>
#       Downloads the pinned cosign binary for this OS/CPU from the official
#       sigstore/cosign release into <cache-dir> and checks its SHA-256 against
#       tool/release/cosign-pins.txt. Nothing runs before the check passes.
#   tool/release/verify_cosign.sh verify <cosign-binary> <asset-dir> [identity]
#       Runs `cosign verify-blob` for every <file>.sigstore.json in <asset-dir>
#       whose <file> exists next to it. Exit code 1 if any check fails.
#   tool/release/verify_cosign.sh matrix <asset-dir> <cache-dir> [version...]
#       fetch + verify for each version (default: every version in the pins).
#
# The identity defaults to the release workflow on main (see
# docs/RELEASE-VERIFIZIEREN.md). The asset directory is read only.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pins="$here/cosign-pins.txt"
issuer='https://token.actions.githubusercontent.com'
default_identity='https://github.com/VectoDE/linefm-radio-app/.github/workflows/release.yml@refs/heads/main'

platform_file() {
  local os arch
  case "$(uname -s)" in
    Linux*) os=linux ;;
    Darwin*) os=darwin ;;
    MINGW* | MSYS* | CYGWIN*) os=windows ;;
    *) echo "unsupported OS: $(uname -s)" >&2; return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64 | amd64) arch=amd64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *) echo "unsupported CPU: $(uname -m)" >&2; return 1 ;;
  esac
  if [ "$os" = windows ]; then echo "cosign-$os-$arch.exe"; else echo "cosign-$os-$arch"; fi
}

sha256_of() {
  if command -v sha256sum > /dev/null; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

fetch() {
  local version="$1" dir="$2" file want got url
  file="$(platform_file)"
  want="$(awk -v v="$version" -v f="$file" '$1 == v && $2 == f {print $3}' "$pins")"
  [ -n "$want" ] || { echo "no pin for cosign $version / $file" >&2; return 1; }
  mkdir -p "$dir/$version"
  url="https://github.com/sigstore/cosign/releases/download/v$version/$file"
  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    --output "$dir/$version/$file.part" "$url"
  got="$(sha256_of "$dir/$version/$file.part")"
  if [ "$got" != "$want" ]; then
    rm -f "$dir/$version/$file.part"
    echo "SHA-256 mismatch for cosign $version: got $got, want $want" >&2
    return 1
  fi
  mv "$dir/$version/$file.part" "$dir/$version/$file"
  chmod +x "$dir/$version/$file"
  echo "$dir/$version/$file"
}

verify() {
  local bin="$1" dir="$2" identity="${3:-$default_identity}" ok=0 failed=0 bundle blob
  "$bin" version 2> /dev/null | grep -E '^GitVersion' || true
  shopt -s nullglob
  for bundle in "$dir"/*.sigstore.json; do
    blob="${bundle%.sigstore.json}"
    [ -f "$blob" ] || continue
    if "$bin" verify-blob --bundle "$bundle" \
      --certificate-identity "$identity" \
      --certificate-oidc-issuer "$issuer" "$blob" > /dev/null 2>&1; then
      ok=$((ok + 1))
    else
      failed=$((failed + 1))
      echo "FAILED: $(basename "$blob")" >&2
      "$bin" verify-blob --bundle "$bundle" --certificate-identity "$identity" \
        --certificate-oidc-issuer "$issuer" "$blob" 2>&1 | tail -3 >&2 || true
    fi
  done
  echo "verified: $ok, failed: $failed"
  [ "$ok" -gt 0 ] && [ "$failed" -eq 0 ]
}

matrix() {
  local dir="$1" cache="$2" status=0 v bin
  shift 2
  local versions=("$@")
  if [ "${#versions[@]}" -eq 0 ]; then
    mapfile -t versions < <(awk '!/^#/ && NF {print $1}' "$pins" | sort -uV)
  fi
  for v in "${versions[@]}"; do
    echo "== cosign $v"
    bin="$(fetch "$v" "$cache")" || { status=1; continue; }
    verify "$bin" "$dir" || status=1
  done
  return "$status"
}

case "${1:-}" in
  fetch) [ $# -eq 3 ] || { sed -n '2,19p' "$0"; exit 2; }; fetch "$2" "$3" ;;
  verify) [ $# -ge 3 ] || { sed -n '2,19p' "$0"; exit 2; }; verify "$2" "$3" "${4:-}" ;;
  matrix) [ $# -ge 3 ] || { sed -n '2,19p' "$0"; exit 2; }; shift; matrix "$@" ;;
  *) sed -n '2,19p' "$0"; exit 2 ;;
esac
