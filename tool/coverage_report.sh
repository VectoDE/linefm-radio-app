#!/usr/bin/env bash
# Coverage evaluation for CI.
#
# Usage (in the repo root):  tool/coverage_report.sh <lcov-base> <lcov-extra|""> <output-dir>
#
# - Filters generated code (lib/l10n/gen/*) out of the measurement. Reason: it is produced by
#   "flutter gen-l10n" and checked for freshness in the "l10n-check" job; tests for it
#   would test the generator, not the app.
# - Adds files that "flutter test" never loaded (they would otherwise be missing from lcov.info and
#   skew the value upwards), taken from the extra lcov of the import run.
# - Writes <output>/lcov.filtered.info, summary.md (table per file) and total.txt
#   (lines "lines=NN.NN" and "branches=NN.NN" or "branches=n/a").
set -euo pipefail

base="${1:?lcov base file is missing}"
extra="${2:-}"
out="${3:?output directory is missing}"
exclude_re='^SF:(.*/)?lib/l10n/gen/'

mkdir -p "$out"
filtered="$out/lcov.filtered.info"

{
  tr -d '\r' <"$base"
  if [ -n "$extra" ] && [ -f "$extra" ]; then
    # Only take over files that are missing from the base.
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
  /^end_of_record/ { drop = 0 }' | awk '
  # Consistency per file (Dart lcov with --branch-coverage reports branches (BRDA) also for
  # lines without a line record (DA), e.g. in multi-line expressions; genhtml then aborts
  # with "branchcov but no linecov"). Branches without a DA line are dropped, the
  # sums LF/LH/BRF/BRH are recomputed from the remaining lines.
  function keep(ln) {
    # Keep a branch only if line and branches match: genhtml rejects
    # "line hit but no branch evaluated" and "branch hit but line not".
    if (!(ln in da)) return 0
    if (da[ln] > 0 && !(taken[ln] > 0)) return 0
    if (da[ln] == 0 && taken[ln] > 0) return 0
    return 1
  }
  function flush(   i, l, a, ln, brf, brh, lf, lh) {
    for (i = 1; i <= n; i++) {
      l = buf[i]
      if (l ~ /^DA:/) { split(substr(l, 4), a, ","); da[a[1] + 0] = a[2] + 0; lf++; if (a[2] + 0 > 0) lh++ }
      else if (l ~ /^BRDA:/) { split(substr(l, 6), a, ","); if (a[4] != "-" && a[4] + 0 > 0) taken[a[1] + 0]++ }
    }
    for (i = 1; i <= n; i++) {
      l = buf[i]
      if (l ~ /^BRDA:/) {
        split(substr(l, 6), a, ",")
        if (!keep(a[1] + 0)) continue
        brf++; if (a[4] != "-" && a[4] + 0 > 0) brh++
      }
    }
    for (i = 1; i <= n; i++) {
      l = buf[i]
      if (l ~ /^BRDA:/) { split(substr(l, 6), a, ","); if (!keep(a[1] + 0)) continue }
      if (l ~ /^(LF|LH|BRF|BRH):/) continue
      if (l == "end_of_record") {
        if (brf > 0) { print "BRF:" brf; print "BRH:" brh + 0 }
        print "LF:" lf + 0; print "LH:" lh + 0
      }
      print l
    }
    n = 0; delete da; delete taken; delete buf
  }
  { buf[++n] = $0 }
  /^end_of_record/ { flush() }' >"$filtered"

# Table per file, ascending by line coverage.
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
    if (c > 12) r = r ", ... (" c " ranges)"
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

# Files under lib/ without any measurement data (loaded by no test, not even by the import run).
grep '^SF:' "$filtered" | sed 's/^SF://' | sort -u >"$out/measured.tmp"
find lib -name '*.dart' ! -path 'lib/l10n/gen/*' | sort >"$out/all.tmp"
comm -13 "$out/measured.tmp" "$out/all.tmp" >"$out/unmeasured.txt"

{
  echo "### Coverage lib/ (without generated code lib/l10n/gen)"
  echo
  echo "**Lines:** ${lines_pct} % (${tlh}/${tlf}), **Branches:** ${br_pct}$([ "$br_pct" = "n/a" ] && echo "" || echo " %") (${tbh:-0}/${tbf:-0})"
  echo
  echo "| File | Lines | Branches | Missing line ranges |"
  echo "| --- | --- | --- | --- |"
  grep -v '^TOTAL|' "$rows" | sort -t'|' -k1,1n | awk -F'|' '{ printf "| %s | %s | %s | %s |\n", $2, $3, $4, ($5 == "" ? "-" : $5) }'
  if [ -s "$out/unmeasured.txt" ]; then
    echo
    echo "**Without measurement data (loaded by no test, not in the denominator, so the value is skewed upwards):** $(wc -l <"$out/unmeasured.txt")"
    echo
    sed 's/^/- `/; s/$/`/' "$out/unmeasured.txt"
  fi
} >"$out/summary.md"

rm -f "$rows" "$out/measured.tmp" "$out/all.tmp"
cat "$out/total.txt"
