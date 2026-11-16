# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Fix warnings from previous code review

## Goal

Fix both Warning findings in task 37's branch review: deliver concurrent external catalog changes to the mutation author, and persist HA move-journal transitions durably before dependent upstream writes. Preserve explicit confirmations, recovery without replay, existing task identities, and file/local behavior.

## Suggestions

Add focused notification and persistence-ordering regression tests. Keep durability changes scoped to HA metadata, document filesystem/platform limits, and preserve existing uncommitted app lockfile changes. No UI change, deployment, publication, push, or live HA mutation is needed.
