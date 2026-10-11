# Brooks-Lint Review

**Mode:** PR Review
**Scope:** All committed changes on `7-android-note-filename` relative to `main`: parent `074d72d..aa9d7be`, including the app submodule update and `4-implemented.md`; app `8e927a9..20ee9e3`, including `src-tauri/src/backend.rs`, `package.json`, `src-tauri/Cargo.toml`, and `src-tauri/tauri.conf.json`.
**Health Score:** 95/100
**Trend:** Stable at 95; the previous review assessed the task plan, so this is not a same-code trend.

The implementation follows the revised plan, but the changed Android behavior has neither successful target compilation nor runtime verification.

## Findings

### Warning

**T5: Coverage Illusion — Android creation and rejection paths remain unverified**

Symptom: `app/src-tauri/src/backend.rs:87–122` changes note creation and adds provider-name validation and cleanup without corresponding behavioral tests. The entire adapter is Android-only. `4-implemented.md:15–21` records 42 passing desktop tests and desktop Clippy, but the Android build stopped before compilation and ADB could not connect. Lines 25–27 explicitly mark canonical creation, reuse, directory moves, metadata errors, mismatched names, and cleanup failure as unverified. This is a verification gap, not a misleading claim in the implementation report.

Source: *Working Effectively with Legacy Code* — protecting behavior under active change; *How Google Tests Software* — change coverage rather than aggregate test counts; *The Art of Unit Testing* — completeness of error-path verification.

Consequence: The desktop suite cannot detect Android compilation errors or establish that MIME inference creates exactly `Note.md` on the affected provider. A provider could still rename the document, turning repeated-copy creation into a failed save rather than restoring working note storage. The new rejection and cleanup guarantees also have no executed evidence for preservation of cached content, move sources, and pre-existing documents.

Remedy: Complete Android compilation with the required SDK, NDK, and Rust targets. Run the planned create/save/shorter-write/relaunch/directory-move scenarios on the affected provider, including existing canonical and legacy files and task/label regressions. Exercise name mismatch, metadata failure, and cleanup denial through a controlled Android integration setup; assert save failure, unchanged cached content and move source, cleanup ownership, and reported cleanup failure with URI. Record Android version, provider, and results. Keep this gap open until those checks succeed; a test that only asserts the MIME argument would not resolve it.

## Review Coverage

- Base detection: `main` is the direct parent base in both repositories. The parent contains one implementation commit, `aa9d7be`; its app pointer adds one implementation commit, `20ee9e3`.
- Generated files: `app/package-lock.json` and `app/src-tauri/Cargo.lock` were excluded from decay analysis. Their diffs contain only the app's version update, with no dependency changes.
- Configuration: Neither the parent nor app root contains `.brooks-lint.yaml`; balanced defaults apply. Version metadata agrees on `0.15.10`.
- R2: The production change stays within `SafBackend`. `NoteStore::replace` writes before replacing cached content (`note.rs:49–52`), and `move_backend_file` writes before removing the source (`commands.rs:45–49`). `set_data_dir` propagates note-write errors and rolls back earlier task moves (`commands.rs:261–267`). No new change-propagation finding.
- R1: The creation routine is longer, but remains linear with clear guard clauses, shallow branching, and explicit failure messages. Its length alone does not justify a finding.
- R3: Canonical name checks reuse `paths::NOTE_FILE`; the change introduces no second filename policy. Synchronized package versions follow the existing release convention.
- R4: Actual-name validation and cleanup address a documented provider contract and the existing destructive move sequence. No speculative abstraction, retry system, or cache was introduced.
- R5: No new imports, interfaces, dependencies, or structural changes. Android filesystem details remain inside the storage adapter.
- R6: The canonical Markdown note retains its existing name and storage contract. Provider mismatches are errors rather than alternative note identities.
- Plugin contract: Version `28.4.0` documents MIME inference for `None` and allows provider sanitization and numbering. Its Rust API exposes fallible `get_name` and URI-based `remove_file`. The implementation preserves existing exact-name reuse and validates only newly created notes before `SafBackend::write` can write content.
- Cleanup inspection: Both name mismatch and metadata failure reach cleanup of the newly returned URI only. Successful cleanup returns the original save error; failed cleanup includes that error, the cleanup failure, and `uri.uri`. Existing exact-name documents return before creation and cleanup.
- Quick Test Check: One T5 warning. There are no changed test files, so mock-abuse and test-obscurity signals do not apply.
- Verification evidence: Native test, Clippy, formatting, and Android/ADB failure results come from the implementation stage at the reviewed commit. Tests were not rerun during this documentation-only review. `git diff --check main...HEAD` in the app passed during review.

## Summary

No concrete implementation defect was found in the reviewed diff; one warning remains for missing Android change verification. Complete target compilation and the planned provider scenarios before treating the filename fix as verified. The revised plan's creation-name safeguard is implemented, while the provider-dependent acceptance criteria remain open.
