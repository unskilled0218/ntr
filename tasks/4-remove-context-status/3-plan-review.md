# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/4-remove-context-status/2-plan.md` at `de7cb81`, checked against `1-goal.md`, app form/token helpers, and both Rust task models. This is a plan review, not an implementation audit.
**Health Score:** 90/100
**Trend:** First run — no trend data.

The plan covers interface removal and compatibility well, but two edit/presentation decisions need correction before implementation.

## Findings

### Warning

**R6 — Domain Model Distortion: Completed priority is hidden from its own picker [guided]**

Symptom: Step 3 preserves `pri:X` whenever no replacement priority is selected, while the existing modal initializes its picker from `task.priority` alone (`app/src/components/EditTaskModal.tsx:37`). Backend completion moves priority into `pri:X` and clears `task.priority` (`app/src-tauri/src/task.rs:104–115`, `server/src/task.rs:101–112`). The plan therefore makes the picker show None for a task whose priority will return on reopening, and it does not distinguish keeping that value from explicitly clearing it.

Source: Domain-Driven Design — Ubiquitous Language; The Mythical Man-Month — Conceptual Integrity.

Consequence: Users cannot reliably inspect or clear a completed task's saved priority. A completed task can reopen with a priority after its picker showed None, contradicting the remaining priority control.

Remedy: Update Step 3 to seed the picker with `task.priority`, falling back to a valid saved `pri:X` for completed tasks. Give edit serialization one pure owner in `app/src/labels.ts`: persist the effective completed priority as one `pri:X`, replace it when changed, and omit it when None is selected. Keep dates and contexts in that same edit serializer so the modal owns user input rather than raw prefix rules. Add cases for unchanged, replaced, and cleared completed priorities, including reopening behavior.

**R6 — Domain Model Distortion: Context-only tasks become blank and cannot be edited [guided]**

Symptom: Step 4 removes context tokens from description and metadata without defining an empty-description presentation. Step 3 keeps the editable description stripped of contexts without revisiting the current `!description.trim()` save guard (`app/src/components/EditTaskModal.tsx:58`). Both Rust parsers accept a nonempty line such as `@phone`, so a context-only task is valid stored data.

Source: A Philosophy of Software Design — Strategic vs. Tactical Programming; Domain-Driven Design — Domain Model pattern.

Consequence: Removing a visible field can produce an apparently blank task row. The same task cannot save changes to project, priority, or due date because its hidden context does not satisfy the description guard.

Remedy: Define a neutral `Task without description` fallback in `app/src/components/TaskItem.tsx` when context hiding leaves no visible description. In `EditTaskModal.submit`, allow an empty description when the original task contains preserved contexts and the serialized result remains nonempty; retain the required-description rule for new tasks and other edits. Test a context-only task's row, edit, save, and subsequent render without exposing its stored contexts.

## Summary

Two warnings produce the baseline score: `100 - 2 × 5 = 90`. Both findings are accepted and addressed in `2-plan.md`; the score describes the reviewed plan before those corrections, not implementation quality.

R1–R5 yielded no additional actionable findings: the affected files belong to one todo feature, shared context matching is already planned, and retained data contracts are justified compatibility boundaries. The Quick Test Check was skipped because only planning documents change; no implementation tests were run.

## Fix Summary

- Completed priority: guided plan correction for effective picker state and one edit serializer, with replace/clear/reopen checks.
- Context-only tasks: guided plan correction for neutral presentation and safe metadata-only edits.
- Clarified the existing Rust date serialization rule: a completed creation date is emitted only after a completion date.
- Implementation code remains unchanged.
