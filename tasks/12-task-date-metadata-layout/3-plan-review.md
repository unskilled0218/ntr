# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/12-task-date-metadata-layout/2-plan.md` at `b5fd2c7`, checked against `1-goal.md`, edit initialization/serialization, exact-token stripping, and app/server tag parsing.
**Health Score:** 90/100
**Trend:** 95 → 90 (−5); the previous review assessed another task's implementation, so this is not a same-scope trend.

The plan preserves date history, but tag restoration and display cleanup need explicit precedence rules to avoid overriding edits or hiding undisplayed data.

## Findings

### Warning

**R6: Domain Model Distortion — Restoring hidden tags can undo an explicit tag edit**

Symptom: The original plan (`2-plan.md:25`) restores non-managed tags whenever their exact old token is absent from the submitted description. If an existing task has `custom:old` and the user types `custom:new`, that rule appends `custom:old` after the submitted text. Both native and server `Task::derived` insert tokens into a tag map in order (`app/src-tauri/src/task.rs:92–95`, `server/src/task.rs:89–92`), so the last value wins. Exact-token deduplication does not distinguish an unchanged hidden field from an intentionally replaced key.

Source: *Domain-Driven Design* — ownership of state changes and preservation of domain intent; *Code Complete* — defensive data transformation.

Consequence: A successful save can return the old custom value despite the user's explicit edit, and the raw description can accumulate conflicting tokens. The same policy can affect colon-containing values such as URLs, since the existing parsers split on the first colon. Preserving hidden metadata would unexpectedly override submitted content.

Remedy: Define submitted non-managed keys as authoritative. Preserve an original hidden tag only when that key is absent from the submitted description, using the backend's nonempty, case-sensitive first-colon token rules. If the user submits a new value for an existing key, do not append its old value. Test changed/unchanged keys, prefix collisions, values containing colons, and local/server parsed results.

**R2: Change Propagation — Date stripping can hide a value that metadata never displays**

Symptom: The original plan renders due/update metadata only from valid effective tag values (`2-plan.md:33–35`) but strips all valid date tokens from the main text independently (`36`). With `due:2026-10-12 due:later`, the backend's last-value rule makes `tags.due` equal `later`. No valid due metadata is rendered, yet the independent cleanup removes `due:2026-10-12`. The same mismatch applies to duplicate updated tags.

Source: *A Philosophy of Software Design* — consistent information ownership across module boundaries; *Code Complete* — explicit invariants for data transformation.

Consequence: The row loses visible date information without relocating it anywhere, even though the raw task still contains it. A change in effective-tag validation can silently alter which description tokens disappear. That conflicts with keeping malformed/legacy content visible and limits trust in the new metadata projection.

Remedy: Compute the validated effective due/update map once and use it for both metadata rendering and description cleanup. Strip valid housekeeping tokens for a key only when a valid effective value for that key is actually displayed. If the effective value is missing/invalid, retain all description tokens for that key. Test valid/invalid duplicates in both orders for due and updated, with unchanged raw task data.

## Review Coverage

- R2: One projection-authority warning, described above. The existing tag transport and raw backup path otherwise keep the production change localized; backend changes remain diagnosis-driven.
- R1: The plan separates clock policy, serialization, display, and verification. Its explicit save-day and legacy-date decisions make the behavior actionable. No cognitive-overload finding.
- R3: Generic tags reuse the existing storage protocol, and shared calendar validation avoids separate date rules. The revised plan makes validated display selection a shared input rather than two competing interpretations.
- R4: No new DTO version, sidecar history, transient-ID registry, backend stamping system, or distributed transaction is proposed. Test-only server work checks an existing boundary. No speculative-complexity finding.
- R5: Production policy stays in app helpers/UI while native/server stores continue accepting canonical raw lines. No layering or dependency change is required.
- R6: One tag-edit precedence warning, described above. Created/updated remain independent, completion grammar is respected, cancelled/rejected saves preserve data, and explicit project-selection semantics are documented.
- Quick Test Check: Skipped because this is a documentation-only review. Proposed controlled-clock, rendered, transport, failed-write, and persistence tests were assessed; the revised plan now adds the two missing precedence/projection scenarios.
- Configuration: No `.brooks-lint.yaml` exists in the parent or app root; balanced defaults apply. Score reflects the original plan's two warnings, now accepted and addressed.
- Verification limits: Source inspection established the last-value-wins parser contract. This review ran no implementation tests or runtime scenarios and does not establish a reproduced device creation-date-loss cause.

## Summary

Two valid warnings were addressed in `2-plan.md`: submitted tag keys must override restored hidden values, and stripping must depend on actually displayed effective dates. The revised plan adds frontend and local/server regression cases for both rules. No implementation code was modified.
