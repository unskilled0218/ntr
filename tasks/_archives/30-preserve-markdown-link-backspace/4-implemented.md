# Implementation

- [Changes](#changes)
- [Verification](#verification)
- [Limitations](#limitations)

## Changes

- Joined note lines using logical Markdown offsets for unmodified Backspace and cancelable backward-deletion `beforeinput`, preserving link syntax and caret position.
- Kept modified-key sequences and composition out of the controlled join, and prevented a handled keydown from being applied again by a subsequent beforeinput.
- Revealed the destination line before restoring its selection, corrected editor-root boundary offsets, and added regression tests for editing, caret, undo, and save behavior.
- Updated the client documentation and version to `0.15.26`. App submodule commit: `8dda72f`.

## Verification

- `npm test`: 45 files and 722 tests passed.
- `npm run build`: passed.
- `cargo test -j 1`: 62 passed; one ignored because it requires `MY_NTR_SERVER_BIN`.
- `cargo clippy --all-targets -j 1`: passed.
- `git diff --check` in the app passed.

## Limitations

- No affected desktop WebView or Android device was available for real-input characterization or before-and-after validation. The reported original deletion mechanism and native caret placement remain unverified.
- The controlled mobile path requires a cancelable `deleteContentBackward` event. Noncancelable events are left native; input-method event ordering and modifier-key provenance can vary by platform.
- Synthetic tests do not execute native contenteditable deletion or prove CSS visibility and caret behavior in a WebView.
