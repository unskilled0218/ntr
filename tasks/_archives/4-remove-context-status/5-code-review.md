# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `4-remove-context-status` versus `main`: parent `0fa7bc8..d85def4` (app pointer and implementation report), including app `0a1e136..4351a00` (25 changed files). Reviewed the changed source, tests, documentation, and release metadata; sampled deeper runtime analysis around serialization, lifecycle state, and filtering. Generated npm/Cargo lockfiles were excluded from design diagnosis; their changes contain only the version bump.
**Health Score:** 95/100
**Trend:** 90 → 95 (+5) across two PR Review records; the preceding record reviewed the plan, so the scopes are not directly comparable.

The interface simplification follows the plan, but edit serialization still permits description text to overwrite lifecycle metadata.

## Findings

### Warning

**R6 — Domain Model Distortion: Free-text descriptions can become task prefixes**

Symptom: `composeEditedTask` constructs prefixes from original task metadata, then appends the editable description without checking whether the Rust parser will interpret its first tokens as additional prefixes (`app/src/labels.ts:55–71`). `EditTaskModal.submit` accepts that output directly (`app/src/components/EditTaskModal.tsx:55–61`). Rust recognizes leading `x`, `(A)`–`(Z)`, and dates before treating the remainder as description (`app/src-tauri/src/task.rs:42–69`); the server uses the same rules. The new serializer's preservation contract therefore fails for missing dates/priorities and prefix-like description text.

Source: Domain-Driven Design — Aggregate Roots and invariant ownership; A Philosophy of Software Design — Information Hiding and Leakage.

Consequence: A description-only edit can silently complete an active task, invent creation/completion metadata, or restore a priority that the picker showed as None. This affects local and server modes because updates replace whole parsed task lines. Examples confirmed against the actual local Rust task model:

- Active task with no priority/date, edited description `x call bank`: serialization is `x call bank @phone`; parsed completion changes from false to true.
- Active task with no creation date, edited description `2026-08-01 meeting`: serialization is `2026-08-01 meeting @phone`; parsed creation date changes from null to `2026-08-01`.
- Completed task with completion date `2026-06-02` and no creation date, edited description `2026-08-01 meeting`: serialization is `x 2026-06-02 2026-08-01 meeting @phone`; parsed creation date becomes `2026-08-01`.
- Completed task with no dates and priority None, edited description `(B) call bank`: serialization is `x (B) call bank @phone`; reopening yields priority B despite the blank priority field.

Remedy: Keep the boundary decision in `composeEditedTask`. When description tokens would be consumed as prefixes, place an existing preserved context or selected project token before the description to stop prefix parsing without changing stored semantics. If no existing token can disambiguate the line, report a clear validation error rather than silently rewriting lifecycle metadata. Add parser-backed round-trip cases for active/completed tasks with missing dates and leading `x`, priority, and date text, including assertions on description and reopened priority. This fixes the new helper's promised invariant without changing the todo.txt format or duplicating prefix policy in the modal.

The parser ambiguity also existed in parts of the former form composer; this finding concerns the newly introduced `composeEditedTask` contract, not a claim that every example is a newly introduced regression. The completed-date example specifically exercises the branch's added date-preserving serialization.

## Verification And Quick Test Check

- `npx vitest run src/labels.test.ts src/components/EditTaskModal.test.tsx`: passed, 49 tests in two files.
- Compiled the current `src/labels.ts` into a temporary bundle and passed four generated lines through the real `app/src-tauri/src/task.rs` parser using the temporary Rust probe from implementation verification. All four reproduced the metadata mismatches above. No source or test fixes were applied.
- `git diff --check main...HEAD` in `app`: passed.
- The implementation report records 292 frontend tests, the production build, 42 native tests, HTTP smoke checks, and six normal-case local parser round-trips at the reviewed app commit. Those broader checks were not rerun during this review.
- Changed behaviors have component/helper coverage, including compact controls, status cleanup, saved sort fallback, multiple contexts, and completed priorities. The existing serialization assertions verify emitted strings but miss the prefix interpretation described above; this gap is included in the same finding rather than counted twice.
- Transport/callback spies observe externally meaningful commands and save payloads; new tests also verify visible task state and pure helper outputs. No separate Mock Abuse or Test Obscurity finding is justified.
- Interactive Tauri/webview checks remain unperformed, as recorded in `4-implemented.md`.

## Summary

One warning yields `100 - 5 = 95`. Address the serializer's parser-boundary invariant before treating the edit-preservation acceptance criteria as complete; no fixes were implemented in this stage.

The 673-line app diff is a size-based Change Propagation signal and merits extra review attention, but the edits stay within one todo feature and its release/test files. R1–R5 produced no additional actionable findings: helpers have bounded responsibilities, context compatibility is intentional, and no new dependency cycle or unrelated module coupling was introduced.
