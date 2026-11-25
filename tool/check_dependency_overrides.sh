#!/usr/bin/env bash
# Every entry under `dependency_overrides:` in pubspec.yaml needs a
# documented reason. The line directly above the entry (or above the
# `dependency_overrides:` key for its first entry) must be a comment of the form
#   # override-reason(<package>): <why, with issue reference>
# Usage: bash tool/check_dependency_overrides.sh [pubspec.yaml]
set -euo pipefail

file="${1:-pubspec.yaml}"
fail=0
in_block=0
declare -A reasons=()

while IFS= read -r raw || [ -n "$raw" ]; do
  line="${raw%$'\r'}"
  if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*override-reason\(([A-Za-z0-9_]+)\):[[:space:]]*[^[:space:]] ]]; then
    reasons["${BASH_REMATCH[1]}"]=1
    continue
  fi
  if [[ "$line" =~ ^dependency_overrides:[[:space:]]*(#.*)?$ ]]; then
    in_block=1
    continue
  fi
  if [ "$in_block" -eq 1 ]; then
    if [[ "$line" =~ ^[^[:space:]#] ]]; then
      in_block=0
    elif [[ "$line" =~ ^\ \ ([A-Za-z0-9_]+): ]]; then
      pkg="${BASH_REMATCH[1]}"
      if [ -z "${reasons[$pkg]:-}" ]; then
        echo "::error file=$file::dependency override '$pkg' has no '# override-reason($pkg): ...' comment"
        fail=1
      else
        echo "Override '$pkg' is documented."
      fi
    fi
  fi
done < "$file"

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "All dependency overrides are documented."
