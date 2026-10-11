# Agent triage conventions

Rules for issue labels and agents. They apply to any repo that uses them.

## Triage labels

| Label             | Meaning                                                 |
| ----------------- | ------------------------------------------------------- |
| `needs-triage`    | The maintainer must evaluate the issue.                 |
| `needs-info`      | The issue waits for more information from the reporter. |
| `ready-for-agent` | The issue is fully specified. An agent may start work.  |
| `ready-for-human` | A person must do the work.                              |
| `wontfix`         | Nobody will act on the issue.                           |

## Priority labels

| Label         | Meaning                                  |
| ------------- | ---------------------------------------- |
| `P0-critical` | Act now. Drop other work.                |
| `P1-next`     | The next item to work on.                |
| `P2-later`    | Planned, but not the next item.          |
| `P3-parked`   | Not planned. Revisit later, or close.    |

Give an issue at most one priority label. The owner applies it.
Priority is separate from triage. An issue can be `ready-for-agent` and `P2-later`.

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

Run `./create-labels.sh OWNER/REPO` to create the triage and priority labels in a repo.
The script skips a label that already exists.
Add `--dry-run` to see what it would do. It needs the `gh` CLI with write access to the repo.
