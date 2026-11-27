#!/usr/bin/env bash
# Refreshes the apt package lists on GitHub-hosted Ubuntu runners.
#
# The runner image ships a packages.microsoft.com source. When that
# repository answers 403 (seen for new Ubuntu releases), "apt-get update"
# fails although none of our steps installs Microsoft packages. Drop every
# source entry that points there before the update; all other sources stay.
set -euo pipefail

shopt -s nullglob
for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  if grep -q 'packages\.microsoft\.com' "$f"; then
    echo "Removing apt source $f (packages.microsoft.com is not needed)"
    sudo rm -f "$f"
  fi
done
if [ -f /etc/apt/sources.list ] && grep -q 'packages\.microsoft\.com' /etc/apt/sources.list; then
  sudo sed -i '/packages\.microsoft\.com/d' /etc/apt/sources.list
fi

sudo apt-get update "$@"
