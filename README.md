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

## Automation

Two shared workflows live in `.github/workflows/`. Other repos call them at tag `v1`.

| Workflow     | Runs when                                                                  | Does                                                                                    |
| ------------ | -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `triage.yml` | An issue opens                                                             | Adds `needs-triage`, unless the issue has a triage label. A fixed rule, no LLM.         |
| `agent.yml`  | A user with write access writes `@claude` in an issue, a comment or a review | Runs Claude Code. It works on a `claude/` branch and opens a pull request. It never merges. |

The agent has no label trigger. Applying `ready-for-agent` does not start it.

### Set up a repo

1. Install the Claude GitHub app on the repo: https://github.com/apps/claude.
   Or run `/install-github-app` in Claude Code.
2. Run `claude setup-token`, then `gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo OWNER/REPO`.
3. Copy `templates/conventions.yml` to `.github/workflows/conventions.yml` in the repo.
4. Test: open an issue. It gets `needs-triage`. Then comment `@claude say hello`.

### Release a change

Callers use tag `v1`. A change reaches them only when you move the tag by hand, after the merge:

    git tag -f v1 && git push -f origin v1

A public repo can call these workflows only while this repo is public.
