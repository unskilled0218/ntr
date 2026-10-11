# goal

## command

- android keeps creating `Note.md (num).txt`. Use Note.md only

## goal

Make Android local note storage use one file named exactly `Note.md` in the selected data directory. Creating and saving notes must preserve that filename, reuse the existing file, and stop producing `.txt` suffixes or numbered copies such as `Note.md (1).txt`.

The saved note must remain readable after repeated edits and app restarts. Selecting or changing an Android data directory must preserve the same canonical filename and note content.

## project findings

- `app/src-tauri/src/paths.rs` already defines the canonical note filename as `Note.md`.
- `app/src-tauri/src/backend.rs` implements Android Storage Access Framework storage in `SafBackend`. Its file lookup matches document display names exactly.
- `SafBackend::existing_or_new_file_uri` creates every missing file with MIME type `text/plain`, including `Note.md`. A provider adding a `.txt` extension would make the next exact-name lookup miss that document and create another copy. Confirm this suspected cause during implementation.
- `SafBackend::write` performs this lookup or creation on each save. Reads also require an exact filename match.
- `app/src-tauri/src/commands.rs` moves notes between data directories through the same backend using `paths::NOTE_FILE`, so directory changes also exercise this creation path.

## acceptance criteria

- In an Android-selected directory without a note file, saving a note creates exactly `Note.md`, with no appended `.txt` extension.
- When `Note.md` already exists, reading and saving use that file and preserve its content except for the user's edits.
- Repeated saves and app restarts keep using the same `Note.md` and create no numbered note copies.
- Changing the Android data directory retains the note content in a file named exactly `Note.md`.
- Existing numbered or suffixed note files are not silently deleted or overwritten by the fix.
- Storage of `todo.txt` and `labels.json`, desktop local storage, and server note behavior continue to work.
- Relevant checks and real Android create/save/relaunch verification are recorded, including the document provider tested and any unavailable verification.
