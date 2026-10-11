# plan

## scope

Fix Android local note creation in `app/src-tauri/src/backend.rs` so the selected directory contains one canonical `Note.md`. Keep exact-name lookup and reuse for subsequent reads and saves. Cover creation, repeated saves, restart, and data-directory changes.

## Implementation Plan

### 1. Confirm the Android filename behavior

- Reproduce the current behavior in a disposable directory using the Android document provider that exhibits the bug, if a device or emulator is available. Save a note repeatedly and inspect actual document display names and contents.
- The installed `tauri-plugin-android-fs` version `28.4.0` forwards the supplied MIME type and filename to `DocumentsContract.createDocument`. Its API documents that providers may append extensions or sequential numbers.
- The current call supplies `Some("text/plain")` even for `Note.md`. Once a provider appends `.txt`, `SafBackend::file_uri` cannot find the canonical name, so the next save requests another document.
- The plugin accepts `None` to infer MIME type from the filename extension. Its `resolve_mime_type` uses Android's extension mapping and falls back to `application/octet-stream` when no mapping exists. Use this existing capability rather than adding a plugin patch or dependency.

### 2. Preserve the Markdown filename during creation

- In `SafBackend::existing_or_new_file_uri`, retain the early return when `file_uri(name)` finds an existing document.
- For `name == paths::NOTE_FILE`, pass `None` as the MIME type to `create_new_file`. Keep `Some("text/plain")` for other filenames so this fix stays limited to note creation.
- Keep the requested name exactly `paths::NOTE_FILE`, which is already `Note.md`. Add a short comment explaining that forcing plain-text MIME can cause Android providers to append `.txt` and defeat exact-name reuse.
- Keep the returned URI for the current write and retain exact-name discovery for future writes and restarts. Do not cache a misnamed document as a substitute for fixing the filename.
- Preserve existing error propagation. `NoteStore::replace` must continue updating its cached content only after the backend write succeeds.
- Directory moves already write through this same method. Confirm that `set_data_dir` needs no separate filename workaround.

### 3. Verify creation, reuse, and persistence

- From `app/src-tauri`, run `cargo test` and `cargo clippy --all-targets`. Existing backend, note persistence, and directory-move tests cover the shared behavior; desktop checks do not compile Android-only code.
- From `app`, run `npm run tauri android build` to compile the actual Android branch when the installed SDK, NDK, and Rust target permit it. Report missing prerequisites rather than installing system packages.
- On Android, select an empty disposable directory, save Markdown content, and inspect it through the document provider. Require exactly `Note.md`, without `.txt` or a numbered suffix.
- Edit and save several times, including replacing a longer note with shorter content. Require one canonical file with the latest exact content.
- Close and relaunch the app, then read and edit the note again. Require the same file and no new copies.
- Repeat with a pre-existing `Note.md`. Include unrelated legacy files such as `Note.md.txt` and `Note.md (1).txt`; verify their names and contents remain unchanged.
- Move the data directory through Settings to another disposable directory. Verify the note arrives as `Note.md`, retains its content, and remains reusable after restart.
- Save tasks and labels in the same Android directory. Verify their existing persistence behavior still works. Use existing native tests for desktop storage and directory-move regressions.
- Record commands, results, Android version, provider, and any unavailable device verification in `4-implemented.md`. A successful build alone does not establish correct provider filename behavior.

## Acceptance Criteria

- First Android note save in an empty selected directory creates exactly `Note.md`.
- Existing `Note.md` is reused for reading and writing, including after app restart.
- Repeated edits produce the latest content in that same file, without `.txt` extensions, numbered copies, or trailing stale content.
- Changing Android data directories preserves note content and the canonical filename.
- Existing suffixed or numbered note files remain untouched.
- `todo.txt`, `labels.json`, desktop local storage, and server note behavior retain their existing contracts.
- Native checks and Android compilation results are recorded. Real provider verification is recorded separately, or explicitly marked unavailable.

## Risks And Decisions

- Android document providers control final display names, and extension-to-MIME mappings differ by Android version. `None` removes the forced plain-text mismatch, but real-device verification remains necessary. If the affected provider still changes `Note.md`, investigate its returned name and MIME mapping before declaring the fix complete; do not substitute numbered-file lookup for canonical storage.
- The exact provider behavior has not yet been reproduced during planning. The plugin source confirms the MIME and naming path, not the user's device outcome.
- Legacy copies can contain different note versions. This task prevents new copies and does not choose, merge, rename, or delete historical content automatically.
- Keep the fix within the existing backend. No frontend, server, storage interface, canonical filename constant, or dependency change is needed for the proposed solution.
- Add no test-only abstraction merely to assert the MIME argument. Existing persistence tests and actual Android provider checks are the meaningful verification for this small platform-specific change.
