# goal

- [command](#command)
- [goal](#goal-1)

## command

Fix critical from previous task code review: tasks/15-server-live-update-recovery/5-code-review.md

## goal

Fix the critical same-destination note-save ordering bug in `app/src/components/NotePane.tsx`. Closing settings without changing the server must not release ownership of an outstanding save or allow a newer save to overlap it. After that save settles, reconcile server state while preserving newer local edits and existing conflict handling. Keep different destinations separately scoped and prevent stale completions from changing current editor state.

Add a regression covering an unchanged-settings context change during a deferred save, followed by newer input and adversarial completion timing. Verify that at most one save to the same destination is outstanding and newer text is never silently replaced. Limit this task to the critical finding; the separate post-save unmount warning is outside scope.
