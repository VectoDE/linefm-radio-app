#!/usr/bin/env bash
# Die App-Version kommt nur aus dem Release bzw. Tag. Dieser Check meldet
# jede fest eingetragene Versionsnummer der App ausserhalb von CHANGELOG.md und
# Tests. Versionen von Abhaengigkeiten (pubspec-Pakete, Action-Pins, Flutter,
# Gradle) bleiben erlaubt, sie muessen fest sein.
# Aufruf: bash tool/check_fixed_versions.sh (im Repository-Wurzelverzeichnis)
set -euo pipefail

sv='[0-9]+\.[0-9]+\.[0-9]+'
fail=0
report() {
  echo "::error::$1"
  fail=1
}

# 1. pubspec.yaml traegt nur den Entwicklungs-Platzhalter.
pub="$(sed -n 's/^version:[[:space:]]*\([^[:space:]#]*\).*/\1/p' pubspec.yaml | head -n1)"
if ! [[ "$pub" =~ ^0\.0\.0-dev\+[0-9]+$ ]]; then
  report "pubspec.yaml: version muss 0.0.0-dev+<n> sein (gefunden: $pub)"
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

# 2. Muster, an denen eine feste App-Version stehen koennte.
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
  # 0.0.0-dev ist der erlaubte Entwicklungs-Platzhalter.
  if out="$(git grep -nIE "$p" -- . "${excludes[@]}" | grep -v '0\.0\.0-dev')"; then
    while IFS= read -r line; do report "Feste Version: $line"; done <<< "$out"
  fi
done

# 3. Vorlagen und Konfiguration: dort hat keine Versionsnummer etwas zu suchen.
if out="$(git grep -nIE "\bv?$sv\b" -- .github/ISSUE_TEMPLATE .github/DISCUSSION_TEMPLATE config)"; then
  while IFS= read -r line; do report "Feste Version in Vorlage/Konfiguration: $line"; done <<< "$out"
fi

if [ "$fail" -ne 0 ]; then
  echo "Die Version kommt aus dem Release. Platzhalter wie vX.Y.Z verwenden."
  exit 1
fi
echo "Keine fest eingetragene App-Version gefunden."
