# Implemented

## Scope

- Auto-link plain HTTP(S) URLs in notes while preserving raw-text round trips, code spans, Markdown destinations, URL punctuation, and escaping.
- Make every visible part of `[label](url)` participate in the existing Ctrl/Cmd-click and touch long-press link gestures.
- Add Shift+Tab dedent for literal tab indentation, including multi-line selections, range restoration, undo grouping, autosave, no-op handling, and IME bypass.
- Persist desktop window position and size with the desktop-only Tauri window-state plugin while leaving mobile startup unchanged.
- Bump the app patch version from `0.15.5` to `0.15.6` across npm, Cargo, and Tauri metadata.
- Add focused renderer, gesture, edit-helper, caret, and component coverage.

## Verification

- Focused Vitest run: 5 files, 62 tests passed.
- `npm test`: 27 files, 256 tests passed.
- `npm run build`: TypeScript and Vite production build passed.
- `cargo check` in `app/src-tauri`: passed on Linux with `tauri-plugin-window-state` `2.4.0`.
- `cargo test` in `app/src-tauri`: 42 tests passed.
- `rustfmt --check --edition 2021 --config skip_children=true src/lib.rs`: passed for the changed Rust file.
- `git diff --check`: passed in the app and root repositories.
- `cargo tree --target aarch64-linux-android -i tauri-plugin-window-state`: confirmed the desktop plugin is absent from the Android dependency graph.
- Repository-wide `cargo fmt --check` remains blocked by pre-existing formatting differences in untouched `build.rs`, `src/http.rs`, and `src/main.rs`; those unrelated files were not changed.
- `cargo check --target aarch64-linux-android` could not complete because the Android NDK compiler `aarch64-linux-android-clang` is unavailable in the environment.
- Manual link, IME, touch, and window geometry checks were not run because the container has no graphical desktop, touch, or IME session.

## Result

Plain web URLs and every visible part of Markdown links now use the existing guarded open-link path without changing note text. Shift+Tab removes one leading literal tab from each selected line and preserves the logical range through the existing history and autosave flow. Desktop launches restore only the last normal window position and size; maximized, fullscreen, visibility, and decoration state are not persisted, and mobile builds do not include the plugin.
