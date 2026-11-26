#!/usr/bin/env bash
# The app version comes only from the release or tag. This check reports
# every hard-coded app version number outside CHANGELOG.md and tests.
# Versions of dependencies (pubspec packages, action pins, Flutter, Gradle)
# stay allowed; they must be pinned.
# Usage: bash tool/check_fixed_versions.sh (from the repository root)
set -euo pipefail

sv='[0-9]+\.[0-9]+\.[0-9]+'
fail=0
report() {
  echo "::error::$1"
  fail=1
}

# 1. pubspec.yaml carries only the development placeholder.
pub="$(sed -n 's/^version:[[:space:]]*\([^[:space:]#]*\).*/\1/p' pubspec.yaml | head -n1)"
if ! [[ "$pub" =~ ^0\.0\.0-dev\+[0-9]+$ ]]; then
  report "pubspec.yaml: version must be 0.0.0-dev+<n> (found: $pub)"
fi

excludes=(
  ':!CHANGELOG.md'
  ':!test/**'
  ':!**/*.lock'
  ':!**/package-lock.json'
  ':!tool/font_fallback.lock.json'
  ':!tool/check_fixed_versions.sh'
  ':!lib/l10n/gen/**'
)

# 2. Patterns where a hard-coded app version might appear.
patterns=(
  "APP_VERSION[\"'[:space:]:=]+v?$sv"
  "appVersion[[:space:]]*[:=][[:space:]]*'v?$sv"
  "defaultValue:[[:space:]]*'v?$sv"
  "msix_version:[[:space:]]*[0-9]"
  "linefm-radio-$sv"
  "linefm-radio-app/(releases/(download|tag)/)?v$sv"
  "linefm-radio-app-web:$sv"
  "tag=v$sv"
  "description:.*v$sv"
  "<release version=\"$sv\""
  "AppVersion=$sv"
  "VERSION_AS_STRING \"[1-9]"
)
for p in "${patterns[@]}"; do
  # 0.0.0-dev is the allowed development placeholder.
  if out="$(git grep -nIE "$p" -- . "${excludes[@]}" | grep -v '0\.0\.0-dev')"; then
    while IFS= read -r line; do report "Hard-coded version: $line"; done <<< "$out"
  fi
done

# 3. Templates and configuration: no version number belongs there.
if out="$(git grep -nIE "\bv?$sv\b" -- .github/ISSUE_TEMPLATE .github/DISCUSSION_TEMPLATE config)"; then
  while IFS= read -r line; do report "Hard-coded version in template/configuration: $line"; done <<< "$out"
fi

if [ "$fail" -ne 0 ]; then
  echo "The version comes from the release. Use placeholders such as vX.Y.Z."
  exit 1
fi
echo "No hard-coded app version found."
