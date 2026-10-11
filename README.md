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

No agent reads issue comments. No agent applies these labels on its own.
This includes the priority labels.
An agent acts on an issue only when the owner applies `ready-for-agent`
or starts the agent by hand.

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
