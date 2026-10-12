#!/usr/bin/env bash
# Set up a repo for these conventions: the labels, the caller workflow and the agent secret.
# Skip each part that is already there.
# Usage: ./setup-repo.sh OWNER/REPO [--dry-run]
# To set the secret too, export CLAUDE_CODE_OAUTH_TOKEN first (from `claude setup-token`).
set -euo pipefail

# All the work is in main, so `bash -s` reads the whole script before main runs.
main() {
  local repo="${1:-}" dry_run="${2:-}"
  if [[ ! "$repo" =~ ^[^/]+/[^/]+$ || ( -n "$dry_run" && "$dry_run" != "--dry-run" ) || $# -gt 2 ]]; then
    echo "Usage: setup-repo.sh OWNER/REPO [--dry-run]" >&2
    exit 2
  fi

  # 1. Labels.
  source_file create-labels.sh | bash -s -- "$repo" ${dry_run:+"$dry_run"}

  # 2. The caller workflow, committed to the default branch.
  local wf=.github/workflows/conventions.yml
  if gh api "repos/$repo/contents/$wf" >/dev/null 2>&1; then
    echo "skip    $wf (exists)"
  elif [[ -n "$dry_run" ]]; then
    echo "would commit $wf"
  else
    gh api -X PUT "repos/$repo/contents/$wf" \
      -f message="Add the agent conventions workflow from $src" \
      -f content="$(source_file templates/conventions.yml | base64 | tr -d '\n')" >/dev/null
    echo "committed $wf"
  fi

  # 3. The agent secret. The token goes to gh on stdin, never on a command line.
  local secret=CLAUDE_CODE_OAUTH_TOKEN
  if gh api "repos/$repo/actions/secrets/$secret" >/dev/null 2>&1; then
    echo "skip    $secret (exists)"
  elif [[ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]]; then
    echo "todo    $secret: export it, then run this script again"
  elif [[ -n "$dry_run" ]]; then
    echo "would set $secret"
  else
    printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN" | gh secret set "$secret" --repo "$repo"
    echo "set     $secret"
  fi

  # 4. The one step a script cannot do.
  echo "check   the Claude GitHub app has access to $repo: https://github.com/settings/installations"
}

src=PedroDnT/agent-triage-conventions

# Read a file of this repo: from the clone when the script runs from one, else from GitHub.
here=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source_file() {
  if [[ -n "$here" && -f "$here/$1" ]]; then
    cat "$here/$1"
  else
    gh api "repos/$src/contents/$1" -H "Accept: application/vnd.github.raw"
  fi
}

main "$@"
