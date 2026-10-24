# goal

- [command](#command)
- [goal](#goal-1)

## command

Fix critical from previous task code review: tasks/16-note-save-ownership/5-code-review.md

## goal

Prevent note recovery from silently replacing newer edits or undo operations that return to the pre-save baseline, including an empty note, after unchanged settings invalidate an outstanding save. Preserve that newer editing intent through save settlement and reconciliation; differing remote text must require an explicit conflict choice unless the newer draft can be safely persisted.

Retain destination-scoped single-flight saves, current-context reads, and existing conflict handling. Add regressions for undo and ordinary edits returning to the baseline, including empty text and no-activation controls. Limit this task to the critical draft-protection finding; the inherited post-recovery unmount warning remains outside scope.
