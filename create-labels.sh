#!/usr/bin/env bash
# Create the triage, priority and epic labels in a repo. Skip any label that already exists.
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
  "needs-triage|ededed|Needs owner triage"
  "needs-info|E99695|Waiting on reporter for more information"
  "ready-for-agent|0e8a16|Fully specified, ready for an agent"
  "ready-for-human|b60205|Requires human implementation or decision"
  "wontfix|ffffff|This will not be worked on"
  "P0-critical|b60205|Act now. Drop other work."
  "P1-next|d93f0b|The next item to work on."
  "P2-later|fbca04|Planned, but not the next item."
  "P3-parked|ededed|Not planned. Revisit later, or close."
  "epic|ededed|Parent issue. The work happens in its child issues."
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
