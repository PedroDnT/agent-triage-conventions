#!/usr/bin/env bash
# Cloud environment setup script: load PedroDnT/agent-os into the session, read-only.
# Best effort: it never fails the session (always exit 0).
# AGENT_OS_TOKEN is optional. Set it only if the clone fails without it: a fine-grained
# token with "Contents: read" on PedroDnT/agent-os only. Never put the token in this file.
# AGENT_OS_URL is a test knob; leave it unset.
set +x

REPO_URL="${AGENT_OS_URL:-https://github.com/PedroDnT/agent-os}"
DEST="$HOME/.agents"

say() { echo "[agent-os] $*"; }

# Replace the token with *** in any text that could reach the log.
redact() {
  if [ -n "${AGENT_OS_TOKEN:-}" ]; then sed "s/${AGENT_OS_TOKEN}/***/g"; else cat; fi
}

# The token is used only inside these git calls. It never goes into .git/config.
authed_url() {
  if [ -n "${AGENT_OS_TOKEN:-}" ] && [[ "$REPO_URL" == https://github.com/* ]]; then
    echo "https://x-access-token:${AGENT_OS_TOKEN}@${REPO_URL#https://}"
  else
    echo "$REPO_URL"
  fi
}

load_repo() {
  export GIT_TERMINAL_PROMPT=0
  local out rc
  if [ -d "$DEST/.git" ]; then
    out=$(git -C "$DEST" fetch -q --depth 1 "$(authed_url)" HEAD 2>&1 \
          && git -C "$DEST" reset -q --hard FETCH_HEAD 2>&1)
    rc=$?
  else
    out=$(git clone -q --depth 1 "$(authed_url)" "$DEST" 2>&1)
    rc=$?
    [ $rc -ne 0 ] && rm -rf "$DEST"
  fi
  if [ $rc -ne 0 ]; then
    echo "$out" | redact | tail -3
    return 1
  fi
  git -C "$DEST" remote set-url origin "$REPO_URL"
  git -C "$DEST" remote set-url --push origin DISABLED   # read-only copy: never push from the cloud
}

link_all() {
  mkdir -p "$HOME/.claude"
  # Global rules: the same link the Mac has (~/.claude/CLAUDE.md -> ~/.agents/AGENTS.md).
  if [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
    say "~/.claude/CLAUDE.md already exists as a real file; leaving it."
  else
    ln -sfn "$DEST/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  fi
  # Shared skills. The repo's own script skips names that already exist as real
  # folders (the account's synced skills) and skips the Mac-only appmap links.
  if [ -f "$DEST/bin/link-skills.sh" ]; then
    bash "$DEST/bin/link-skills.sh"
  else
    say "bin/link-skills.sh not found; skills not linked."
  fi
}

if load_repo && [ -f "$DEST/AGENTS.md" ]; then
  link_all
  n=$(find "$HOME/.claude/skills" -maxdepth 1 -type l -lname "$DEST/skills/*" 2>/dev/null | wc -l)
  say "loaded: global AGENTS.md and $n shared skills (commit $(git -C "$DEST" rev-parse --short HEAD))."
else
  say "could not load agent-os (private repo not authorized here? set AGENT_OS_TOKEN). Continuing without it."
fi
exit 0
