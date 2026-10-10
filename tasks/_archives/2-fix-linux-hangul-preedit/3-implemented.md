# Implemented

## Scope

- Enable WebKitGTK input-method preedit on the existing Tauri webview during Linux startup so Hangul composition can render inline at the caret.
- Keep native IME-owned DOM intact during composition and prevent transient preedit text from entering history or autosave.
- Normalize, record, and save the committed composition once through the existing note editor path.
- Add component coverage for progressive Hangul preedit DOM ownership, transient-save suppression, committed saves, and ordinary input behavior.
- Add the Linux-only `webkit2gtk` dependency and bump the app patch version from `0.15.4` to `0.15.5` across npm, Cargo, and Tauri metadata.

## Verification

- `npm test -- --run src/components/NotePane.test.tsx`: 16 tests passed.
- `npm test`: 27 files, 240 tests passed.
- `npm run build`: TypeScript and Vite production build passed.
- `cargo check` in `app/src-tauri`: passed on Linux, including the WebKitGTK extension API.
- `cargo test` in `app/src-tauri`: 42 tests passed.
- `rustfmt --check --edition 2021 --config skip_children=true src/lib.rs`: passed for the changed Rust file.
- `git diff --check`: passed in the app and root repositories.
- Repository-wide `cargo fmt --check` remains blocked by pre-existing formatting differences in untouched `build.rs`, `src/http.rs`, and `src/main.rs`; those unrelated files were not changed.
- Manual Linux Hangul IME verification was not run because the container has no graphical desktop/IME session. The native path requires a real WebKitGTK runtime with fcitx5 or IBus to confirm progressive inline preedit and candidate positioning.

## Result

Linux startup now re-enables WebKitGTK's native preedit after Wry creates the main webview. The note editor leaves each in-progress IME update visible without replacing WebKit's DOM, does not save a partial consonant/vowel sequence even if an older debounce fires, and resumes Markdown rendering, history, and autosave when composition commits. Other platforms remain unchanged through target-specific imports and dependencies.
