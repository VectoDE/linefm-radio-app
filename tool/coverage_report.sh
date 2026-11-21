#!/usr/bin/env bash
# Coverage-Auswertung fuer die CI (Issue #106).
#
# Aufruf (im Repo-Root):  tool/coverage_report.sh <lcov-basis> <lcov-zusatz|""> <ausgabeordner>
#
# - Filtert generierten Code (lib/l10n/gen/*) aus der Messung. Begruendung: Er wird von
#   "flutter gen-l10n" erzeugt und im Job "l10n-check" auf Aktualitaet geprueft; Tests dafuer
#   wuerden den Generator testen, nicht die App.
# - Ergaenzt Dateien, die "flutter test" nie geladen hat (sie fehlen sonst in lcov.info und
#   verfaelschen den Wert nach oben), aus dem Zusatz-lcov des Import-Laufs.
# - Schreibt <ausgabe>/lcov.filtered.info, summary.md (Tabelle je Datei) und total.txt
#   (Zeilen "lines=NN.NN" und "branches=NN.NN" bzw. "branches=n/a").
set -euo pipefail

base="${1:?lcov-Basisdatei fehlt}"
extra="${2:-}"
out="${3:?Ausgabeordner fehlt}"
exclude_re='^SF:(.*/)?lib/l10n/gen/'

mkdir -p "$out"
filtered="$out/lcov.filtered.info"

{
  tr -d '\r' <"$base"
  if [ -n "$extra" ] && [ -f "$extra" ]; then
    # Nur Dateien uebernehmen, die in der Basis fehlen.
    awk -v basefile="$base" '
      BEGIN {
        while ((getline l < basefile) > 0) {
          sub(/\r$/, "", l)
          if (l ~ /^SF:/) seen[substr(l, 4)] = 1
        }
      }
      /^SF:/ { skip = (substr($0, 4) in seen) }
      { if (!skip) print }
      /^end_of_record/ { skip = 0 }' < <(tr -d '\r' <"$extra")
  fi
} | awk -v ex="$exclude_re" '
  /^SF:/ { drop = ($0 ~ ex) }
  { if (!drop) print }
  /^end_of_record/ { drop = 0 }' >"$filtered"

# Tabelle je Datei, aufsteigend nach Zeilenabdeckung.
rows="$out/rows.tmp"
awk '
  function flush_ranges(f,   i, s, e, r, c, n) {
    n = mc[f]; r = ""; c = 0; i = 1
    while (i <= n) {
      s = miss[f, i]; e = s
      while (i < n && miss[f, i + 1] == e + 1) { i++; e = miss[f, i] }
      if (c < 12) { r = r (r == "" ? "" : ", ") (s == e ? s : s "-" e) }
      c++; i++
    }
    if (c > 12) r = r ", ... (" c " Bereiche)"
    return r
  }
  /^SF:/ { f = substr($0, 4); files[++n] = f; next }
  /^DA:/ {
    split(substr($0, 4), a, ",")
    lf[f]++
    if (a[2] + 0 > 0) lh[f]++; else miss[f, ++mc[f]] = a[1] + 0
    next
  }
  /^BRDA:/ {
    split(substr($0, 6), b, ",")
    brf[f]++
    if (b[4] != "-" && b[4] + 0 > 0) brh[f]++
    next
  }
  END {
    for (i = 1; i <= n; i++) {
      f = files[i]
      pct = lf[f] > 0 ? lh[f] * 100 / lf[f] : 100
      bp = brf[f] > 0 ? sprintf("%.1f %% (%d/%d)", brh[f] * 100 / brf[f], brh[f], brf[f]) : "n/a"
      printf "%08.3f|`%s`|%.1f %% (%d/%d)|%s|%s\n", pct, f, pct, lh[f], lf[f], bp, flush_ranges(f)
      tlf += lf[f]; tlh += lh[f]; tbf += brf[f]; tbh += brh[f]
    }
    printf "TOTAL|%d|%d|%d|%d\n", tlf, tlh, tbf, tbh
  }' "$filtered" >"$rows"

total_line=$(grep '^TOTAL|' "$rows")
IFS='|' read -r _ tlf tlh tbf tbh <<<"$total_line"
lines_pct=$(awk -v h="$tlh" -v f="$tlf" 'BEGIN { if (f > 0) printf "%.2f", h * 100 / f; else print "0.00" }')
if [ "${tbf:-0}" -gt 0 ]; then
  br_pct=$(awk -v h="$tbh" -v f="$tbf" 'BEGIN { printf "%.2f", h * 100 / f }')
else
  br_pct="n/a"
fi
printf 'lines=%s\nbranches=%s\n' "$lines_pct" "$br_pct" >"$out/total.txt"

# Dateien unter lib/ ohne jede Messdaten (von keinem Test geladen, auch nicht vom Import-Lauf).
grep '^SF:' "$filtered" | sed 's/^SF://' | sort -u >"$out/measured.tmp"
find lib -name '*.dart' ! -path 'lib/l10n/gen/*' | sort >"$out/all.tmp"
comm -13 "$out/measured.tmp" "$out/all.tmp" >"$out/unmeasured.txt"

{
  echo "### Coverage lib/ (ohne generierten Code lib/l10n/gen)"
  echo
  echo "**Zeilen:** ${lines_pct} % (${tlh}/${tlf}), **Zweige:** ${br_pct}$([ "$br_pct" = "n/a" ] && echo "" || echo " %") (${tbh:-0}/${tbf:-0})"
  echo
  echo "| Datei | Zeilen | Zweige | Fehlende Zeilenbereiche |"
  echo "| --- | --- | --- | --- |"
  grep -v '^TOTAL|' "$rows" | sort -t'|' -k1,1n | awk -F'|' '{ printf "| %s | %s | %s | %s |\n", $2, $3, $4, ($5 == "" ? "-" : $5) }'
  if [ -s "$out/unmeasured.txt" ]; then
    echo
    echo "**Ohne Messdaten (von keinem Test geladen, nicht im Nenner, daher ist der Wert nach oben verzerrt):** $(wc -l <"$out/unmeasured.txt")"
    echo
    sed 's/^/- `/; s/$/`/' "$out/unmeasured.txt"
  fi
} >"$out/summary.md"

rm -f "$rows" "$out/measured.tmp" "$out/all.tmp"
cat "$out/total.txt"
