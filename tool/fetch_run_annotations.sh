#!/usr/bin/env bash
# Downloads the check-run annotations (the warnings and errors GitHub shows on
# the run page, such as action deprecation notices) of every finished job of a
# workflow run into OUT_DIR, one file per job named after the job with the
# suffix .annotations. Each line is "LEVEL<TAB>[TITLE: ]MESSAGE".
# tool/check_build_logs.py --annotations scans these files.
#
# Usage: fetch_run_annotations.sh REPO RUN_ID ATTEMPT OUT_DIR [SKIP_JOB_NAME]
# Needs GH_TOKEN with actions:read (jobs) and checks:read (annotations); the
# default GITHUB_TOKEN can read check runs of its own repository.
set -euo pipefail

repo=$1 run_id=$2 attempt=$3 out=$4 skip=${5:-}
mkdir -p "$out"

jobs=$(gh api --paginate \
  "repos/$repo/actions/runs/$run_id/attempts/$attempt/jobs?per_page=100" \
  --jq '.jobs[] | select(.status == "completed")
        | select(.conclusion != "skipped")
        | "\(.id)\t\(.name)"')

failed=0
while IFS=$'\t' read -r id name; do
  [ -n "$id" ] || continue
  if [ -n "$skip" ] && { [ "$name" = "$skip" ] || [[ "$name" == *" / $skip" ]]; }; then
    continue
  fi
  file="$out/$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_').annotations"
  # The job id doubles as the id of its check run.
  if ! gh api --paginate "repos/$repo/check-runs/$id/annotations?per_page=100" \
      --jq '.[] | ((if (.title // "") == "" then "" else .title + ": " end) + .message) as $text
             | "\(.annotation_level)\t\($text | gsub("[\r\n\t]+"; " "))"' \
      >"$file"; then
    echo "::error::cannot read annotations of job '$name'"
    rm -f "$file"
    failed=1
  fi
done <<<"$jobs"

exit "$failed"
