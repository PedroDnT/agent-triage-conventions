#!/usr/bin/env bash
# Create the five triage labels in a repo. Skip any label that already exists.
# Usage: ./create-labels.sh OWNER/REPO [--dry-run]
set -euo pipefail

repo="${1:-}"
dry_run="${2:-}"

if [[ ! "$repo" =~ ^[^/]+/[^/]+$ || ( -n "$dry_run" && "$dry_run" != "--dry-run" ) || $# -gt 2 ]]; then
  echo "Usage: $0 OWNER/REPO [--dry-run]" >&2
  exit 2
fi

# name|color|description
labels=(
  "needs-triage|d4c5f9|The maintainer must evaluate the issue."
  "needs-info|fbca04|The issue waits for more information from the reporter."
  "ready-for-agent|0e8a16|The issue is fully specified. An agent may start work."
  "ready-for-human|1d76db|A person must do the work."
  "wontfix|ffffff|Nobody will act on the issue."
)

existing="$(gh api --paginate "repos/$repo/labels" --jq '.[].name')"

for entry in "${labels[@]}"; do
  IFS='|' read -r name color description <<<"$entry"
  if grep -qixF -- "$name" <<<"$existing"; then
    echo "skip    $name (exists)"
  elif [[ "$dry_run" == "--dry-run" ]]; then
    echo "would create $name"
  else
    gh api -X POST "repos/$repo/labels" \
      -f name="$name" -f color="$color" -f description="$description" >/dev/null
    echo "created $name"
  fi
done
