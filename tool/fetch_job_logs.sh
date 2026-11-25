#!/usr/bin/env bash
# Downloads the log of every finished job of a workflow run into OUT_DIR, one
# file per job named after the job. Used by the build log gate together with
# tool/check_build_logs.py, which only scans local files.
#
# Usage: fetch_job_logs.sh REPO RUN_ID ATTEMPT OUT_DIR [SKIP_JOB_NAME]
# Needs GH_TOKEN with actions:read. gh follows the redirect of the log endpoint
# to the pre-signed storage URL without sending the token along.
#
# Skipped and cancelled jobs have no log worth scanning and are left out. A log
# that stays missing (404 after retries) or has expired (410) fails the script:
# an unreadable log cannot be shown to be clean.
set -euo pipefail

repo=$1 run_id=$2 attempt=$3 out=$4 skip=${5:-}
mkdir -p "$out"

esc=()
if gh api --help 2>/dev/null | grep -q -- '--allow-escape-sequences'; then
  # Newer gh refuses raw logs with ANSI colour codes without this flag.
  esc=(--allow-escape-sequences)
fi

jobs=$(gh api --paginate \
  "repos/$repo/actions/runs/$run_id/attempts/$attempt/jobs?per_page=100" \
  --jq '.jobs[] | select(.status == "completed")
        | select(.conclusion != "skipped" and .conclusion != "cancelled")
        | "\(.id)\t\(.name)"')

failed=0
while IFS=$'\t' read -r id name; do
  [ -n "$id" ] || continue
  if [ -n "$skip" ] && { [ "$name" = "$skip" ] || [[ "$name" == *" / $skip" ]]; }; then
    continue
  fi
  file="$out/$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_').log"
  ok=0
  for try in 1 2 3 4 5 6; do
    if err=$(gh api "${esc[@]}" "repos/$repo/actions/jobs/$id/logs" 2>&1 >"$file"); then
      ok=1
      break
    fi
    if grep -q 'HTTP 410' <<<"$err"; then
      echo "::error::log of job '$name' has expired (410)"
      break
    fi
    if grep -q 'HTTP 404' <<<"$err" && [ "$try" -lt 6 ]; then
      # A finished job's log can take a moment to become available.
      sleep 10
      continue
    fi
    echo "::error::cannot read log of job '$name': $err"
    break
  done
  [ "$ok" = 1 ] || { rm -f "$file"; failed=1; }
done <<<"$jobs"

exit "$failed"
