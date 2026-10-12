# Agent triage conventions

Rules for issue labels and agents. They apply to any repo that uses them.

## Triage labels

| Label             | Meaning                                    |
| ----------------- | ------------------------------------------ |
| `needs-triage`    | Needs owner triage                         |
| `needs-info`      | Waiting on reporter for more information   |
| `ready-for-agent` | Fully specified, ready for an agent        |
| `ready-for-human` | Requires human implementation or decision  |
| `wontfix`         | This will not be worked on                 |

## Priority labels

| Label         | Meaning                                  |
| ------------- | ---------------------------------------- |
| `P0-critical` | Act now. Drop other work.                |
| `P1-next`     | The next item to work on.                |
| `P2-later`    | Planned, but not the next item.          |
| `P3-parked`   | Not planned. Revisit later, or close.    |

Give an issue at most one priority label. The owner applies it.
Priority is separate from triage. An issue can be `ready-for-agent` and `P2-later`.

## Epic label

| Label  | Meaning                                              |
| ------ | ---------------------------------------------------- |
| `epic` | Parent issue. The work happens in its child issues.  |

Link the child issues to the epic with GitHub sub-issues.
Never apply `ready-for-agent` to an epic. An agent takes a child issue, not the epic.

## What a label does

No agent applies these labels on its own. This includes the priority labels.
One exception: the triage workflow adds `needs-triage` to a new issue by a fixed rule, with no LLM.

An agent acts on an issue only in two cases:

1. The owner applies `ready-for-agent`.
2. A user with write access writes `@claude` in an issue, a comment or a review.

An agent reads the comments of an issue only when one of these two cases starts it.

After someone answers a `needs-info` issue, change the label by hand.

## Rules

1. GitHub rejects a label that does not exist. Create the label before you use it.
2. Check the labels with `gh api repos/OWNER/REPO/labels`.
3. Claim an issue before you write: assign it, then comment `Claimed by: <agent> · branch <branch>`.
4. Open pull requests ready for review, not as drafts, unless the repo says otherwise.

## Create the labels

The script lives in this repo only. Run it from a clone of this repo:

    ./create-labels.sh OWNER/REPO --dry-run

Or run it from any folder, without a clone:

    gh api repos/PedroDnT/agent-triage-conventions/contents/create-labels.sh \
      -H "Accept: application/vnd.github.raw" | bash -s -- OWNER/REPO --dry-run

The script creates the triage, priority and epic labels. It skips a label that already exists.
Remove `--dry-run` to create the labels. It needs the `gh` CLI with write access to the target repo.
`setup-repo.sh` runs this script too (see "Set up a repo").

## Automation

Two shared workflows live in `.github/workflows/`. Other repos call them at tag `v1`.

| Workflow     | Runs when                                                                  | Does                                                                                    |
| ------------ | -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `triage.yml` | An issue opens                                                             | Adds `needs-triage`, unless the issue has a triage label. A fixed rule, no LLM.         |
| `agent.yml`  | A user with write access writes `@claude` in an issue, a comment or a review | Runs Claude Code. It pushes a `claude/` branch and posts a link. You open the pull request. |

The agent has no label trigger. Applying `ready-for-agent` does not start it.

Every repo's agent gets the same base rules (`claude_args` in `agent.yml`): read the repo's `AGENTS.md` or `CLAUDE.md` first, never change labels, never merge, reply short in the language of the request, no em dashes.

### Set up a repo

`setup-repo.sh` creates the labels, commits `templates/conventions.yml` as `.github/workflows/conventions.yml` on the default branch, and sets the `CLAUDE_CODE_OAUTH_TOKEN` secret. It skips each part that is already there.

Do once:

1. Install the Claude GitHub app with "All repositories": https://github.com/apps/claude. Then every new repo has it.
2. Run `claude setup-token` and keep the token.

For each repo:

1. Put the token in your shell, without shell history: `read -rs CLAUDE_CODE_OAUTH_TOKEN && export CLAUDE_CODE_OAUTH_TOKEN`.
2. `./setup-repo.sh OWNER/REPO --dry-run`, then again without `--dry-run`.
   Without a clone: `gh api repos/PedroDnT/agent-triage-conventions/contents/setup-repo.sh -H "Accept: application/vnd.github.raw" | bash -s -- OWNER/REPO`.
3. Test: open an issue. It gets `needs-triage`. Then comment `@claude say hello`.

The script commits straight to the default branch. A repo that protects that branch rejects the commit. Copy the workflow in a pull request there.

### Debug a failed run

A failed run says only "Claude encountered an error". The `debug` input of `agent.yml` shows the full output in the job log.
The template sets `debug` from the repo variable `CLAUDE_AGENT_DEBUG`.

Warning: the full output can hold secrets, and the job log of a public repo is public. Turn debug off when you have the error.

1. `gh variable set CLAUDE_AGENT_DEBUG --body true --repo OWNER/REPO`
2. Write `@claude` again, then read the job log.
3. `gh variable delete CLAUDE_AGENT_DEBUG --repo OWNER/REPO`

A caller that passes `debug` needs a `v1` that has the input. Move the tag first (see "Release a change").

### Release a change

Callers use tag `v1`. A change reaches them only when you move the tag by hand, after the merge:

    git tag -f v1 && git push -f origin v1

A public repo can call these workflows only while this repo is public.

## Cloud sessions: load agent-os

`templates/cloud-setup-agent-os.sh` is a setup script for the Claude Code cloud environment. It clones the private repo `PedroDnT/agent-os` (read-only) into `~/.agents`, links the global `AGENTS.md` to `~/.claude/CLAUDE.md`, and links the shared skills.

1. In the cloud environment menu, choose Edit, then paste the script under Setup script.
2. If the log says `could not load agent-os`, add the environment variable `AGENT_OS_TOKEN`: a fine-grained token with Contents read-only on `agent-os` only.
3. In a new session, check `ls ~/.agents` and `readlink ~/.claude/CLAUDE.md`.

Never commit to `agent-os` from the cloud. Its autosync on the Mac pushes but never pulls, so a commit from elsewhere would block it.
