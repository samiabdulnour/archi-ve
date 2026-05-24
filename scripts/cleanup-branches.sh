#!/usr/bin/env bash
# Delete all remote branches except main.
# Run from your local machine where you're authenticated to push to GitHub.
#
# Usage:
#   bash scripts/cleanup-branches.sh           # dry run, shows what would be deleted
#   bash scripts/cleanup-branches.sh --apply   # actually deletes
#
# Assumes the remote is named "origin".
set -euo pipefail

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then APPLY=1; fi

git fetch --prune origin

BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/remotes/origin/ \
  | grep -v 'origin/main$' \
  | grep -v 'origin/HEAD' \
  | sed 's|origin/||')

if [[ -z "$BRANCHES" ]]; then
  echo "No remote branches to delete."
  exit 0
fi

COUNT=$(echo "$BRANCHES" | wc -l | tr -d ' ')
echo "Found $COUNT remote branches besides main:"
echo "$BRANCHES" | sed 's/^/  /'
echo

if [[ "$APPLY" -ne 1 ]]; then
  echo "Dry run. Re-run with --apply to delete them."
  exit 0
fi

# Push deletes in chunks of 20 to keep each request small.
echo "$BRANCHES" | xargs -n 20 git push origin --delete

echo
echo "Done. Local tracking refs:"
git fetch --prune origin
git for-each-ref --format='%(refname:short)' refs/remotes/origin/
