# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/7-android-note-filename/2-plan.md` at `7668471`, checked against `1-goal.md`, the native storage backend, directory-move code, and Android filesystem plugin version `28.4.0`.
**Health Score:** 95/100
**Trend:** 90 → 95 (+5) from the previous PR Review; scopes differ, so this is not a same-code quality comparison.

The plan keeps the fix local, but must validate the provider's actual filename before accepting a new note document.

## Findings

### Warning

**R2: Change Propagation — A renamed document can falsely satisfy a directory move**

Symptom: `2-plan.md:19–23` changes MIME selection and accepts the returned URI without validating the resulting filename. The risk at line 49 is deferred to device investigation. The plugin explicitly permits providers to change names even with inferred MIME. `app/src-tauri/src/commands.rs:48–49` removes the source after the destination backend reports a successful write.

Source: *Software Engineering at Google* — Hyrum's Law; *Code Complete* — Defensive Programming and explicit error paths. The adapter currently relies on provider naming behavior that the dependency does not guarantee.

Consequence: If a provider still renames `Note.md`, saves can report success while later exact-name reads miss the content. A directory move can delete the canonical source and then load an empty note from the destination. Changing MIME alone does not close that failure path.

Remedy: For newly created notes, obtain the actual display name through the plugin and require `Note.md` before writing content or reporting success. Reject a mismatch with an explicit error, clean up only the empty document created by this attempt, and preserve cleanup failures in the reported error. Keep existing and legacy documents untouched. Verify that rejection preserves cached note content and the directory-move source. Keep MIME inference as the primary naming fix rather than adding rename retries or numbered-file lookup.

## Review Coverage

- R1: The proposed conditional is small and readable. No cognitive-overload finding.
- R2: One provider-contract finding, described above. The intended single-backend change otherwise limits propagation.
- R3: The plan reuses `paths::NOTE_FILE` and plugin MIME inference. No duplicated naming policy is introduced.
- R4: No new interfaces, caches, plugin patches, or test-only abstractions are proposed. A local filename check is justified by the existing destructive move sequence.
- R5: No new dependency or layering change is proposed. Android behavior remains inside `SafBackend`.
- R6: The canonical Markdown note remains `Note.md`; no domain-model finding.
- Quick Test Check: Skipped because this review changes documentation only. The plan's verification steps were assessed for the identified provider failure path.
- Configuration: No root `.brooks-lint.yaml` was found; balanced defaults apply.

## Summary

One warning was accepted and addressed in `2-plan.md`: validate new note names and fail before writing a misnamed destination. The revised plan also specifies cleanup ownership, failure-path verification, and the distinction between unavailable device checks and completed acceptance criteria. Implementation code was not changed.
