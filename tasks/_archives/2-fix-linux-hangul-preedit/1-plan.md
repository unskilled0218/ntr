# 2 - Show in-progress Hangul composition on Linux

## Goal

On the Linux Tauri desktop app, show the in-progress Hangul preedit after every consonant/vowel keystroke (for example `ㅎ` -> `하` -> `한`) instead of leaving the note unchanged until the IME commits a complete syllable. Preserve the current committed note text, caret, Markdown highlighting, undo grouping, shortcuts, and autosave behavior on every platform.

## Root cause

The frontend already has the correct high-level IME contract in `app/src/components/NotePane.tsx`: it leaves the contenteditable DOM under the browser's control between `compositionstart` and `compositionend`, bypasses custom key handling while composing, and repaints only after the composition commits. The missing preedit is native to the Linux WebView. This app currently resolves Tauri `2.11.3` and Wry `0.55.1`; Wry unconditionally calls `set_enable_preedit(false)` on WebKitGTK's input method context. Consequently WebKitGTK does not deliver/render the inline preedit and the contenteditable only changes when the IME commits the complete character. This is the behavior addressed by the still-open upstream Wry PR [tauri-apps/wry#1724](https://github.com/tauri-apps/wry/pull/1724) and Tauri issue [tauri-apps/tauri#11412](https://github.com/tauri-apps/tauri/issues/11412).

Do not implement a JavaScript Hangul composer or a synthetic composition overlay. Both would duplicate IME behavior, interfere with candidate selection and non-Korean IMEs, and risk inserting the preedit twice. Enable WebKitGTK's native preedit instead.

## Native Linux change

### `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`

- Add `webkit2gtk = "2"` under `[target.'cfg(target_os = "linux")'.dependencies]`. Tauri already resolves this crate transitively; the direct, Linux-only dependency makes its extension traits available to application code without adding it to Windows, macOS, Android, or iOS builds.
- Regenerate `Cargo.lock` normally. Do not pin the application to the unmerged Wry PR or introduce a git dependency: Tauri exposes the created native WebView, so the setting can be changed through the stable WebKitGTK API after Wry creates it.

### `app/src-tauri/src/lib.rs`

- In the existing `setup` hook, add a `#[cfg(target_os = "linux")]` block that gets the configured `main` webview window through `app.get_webview_window("main")`, calls `with_webview`, obtains the underlying `webkit2gtk::WebView` from `PlatformWebview::inner()`, then obtains its input method context and calls `set_enable_preedit(true)`.
- Import the required `webkit2gtk::prelude::*` traits only on Linux. Propagate a missing-window or `with_webview` failure through the setup result instead of silently shipping without the fix; treat a missing input method context as a no-op because WebKitGTK exposes it as optional.
- Apply the setting once during setup, before the user can focus the note. Keep this native change platform-gated; the WebView implementations on Windows, Apple platforms, and Android already own their respective IME behavior.

This intentionally opts all Linux WebKitGTK versions into native preedit. Wry disabled it to avoid old fcitx popup-positioning behavior, while current WebKitGTK (the upstream report verifies 4.1 / 2.50.x) supports correct inline composition. The runtime verification below must include the project's supported Linux environment; if an older WebKitGTK exhibits candidate-window positioning problems, document or raise the Linux WebKitGTK minimum rather than falling back to invisible composition.

## Composition and autosave safety

### `app/src/components/NotePane.tsx`

- Keep the existing rule that `onInput` must not call `paint` during composition; replacing `innerHTML` while WebKitGTK owns the preedit would cancel or corrupt the IME session.
- Move the composing check before normal edit recording. While composing, update the status to `Editing...` but do not record history, repaint Markdown, or arm autosave for the transient preedit. The committed text remains handled once by `onCompositionEnd`, which repaints, records one `chunk` history entry, and schedules the save.
- Add a composing guard to `flushNote` so a timer armed by an earlier edit cannot persist a transient preedit while a new composition is active. `onCompositionEnd` will re-arm the debounce for the committed value. Preserve the existing conflict and single-flight guards.
- Leave `onKeyDown`'s `nativeEvent.isComposing` / `composingNote` bypass unchanged so Space, Enter, Tab, undo, cut, and copy continue to belong to the IME during composition.

## Tests

### `app/src/components/NotePane.test.tsx`

- Add a composition helper/test sequence that manually mirrors browser DOM updates because jsdom does not implement an IME: dispatch `compositionstart`, expose successive Hangul preedit values in the contenteditable, and dispatch composing `input` events.
- Assert that each preedit value remains in the DOM immediately and that the component does not repaint/replace the IME-owned line while composition is active.
- Advance the save debounce during composition and assert `putNote` is not called with an intermediate value.
- Dispatch `compositionend` with the committed Hangul syllable/word, then assert the DOM is normalized through the existing Markdown/caret path and autosave persists the committed text exactly once.
- Retain the existing composing-Space regression test and add coverage that ordinary non-IME input still repaints and saves as before if the new early return changes handler structure.

The native `set_enable_preedit` call cannot be meaningfully exercised by jsdom or a headless Rust unit test. Its required regression test is the Linux Tauri runtime check below; `cargo check` on Linux provides API and cfg coverage.

## Version

Bump the app patch version from `0.15.4` to `0.15.5` consistently in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`.

## Out of scope

Changing the server; implementing Hangul composition in JavaScript; changing the note editor from contenteditable; changing Markdown rendering; adding per-IME settings; changing candidate selection UI; enabling preedit on non-Linux platforms; vendoring or forking Wry.

## Verification

- Run `npm test` and `npm run build` in `app/`.
- Run `cargo fmt --check`, `cargo check`, and `cargo test` in `app/src-tauri/` on Linux.
- Run the desktop app on Linux with the user's Hangul IME. In the note, type a sequence such as `ㅎ`, `ㅏ`, `ㄴ`, `ㄱ`, `ㅡ`, `ㄹ` and verify the inline text visibly progresses through each preedit state (for example `ㅎ` -> `하` -> `한`) before commit, with the candidate/preedit UI anchored at the caret.
- Pause longer than the autosave delay after an intermediate consonant/vowel and confirm no transient preedit is saved. Complete the syllable/word and confirm the committed Hangul is saved once and survives reload.
- Compose around existing text and Markdown markers, across multiple syllables, and after moving the caret; confirm caret placement, raw Markdown reveal, highlighting after commit, and undo as one composition chunk.
- While composing, press IME-owned Space/Enter and confirm the editor's custom Space/Enter handlers do not run. Then verify ordinary English typing, Space, Enter, Tab, paste, undo, cut/copy, blur save, and note conflict handling still behave normally.
- Smoke-test a non-Linux build/check if available to confirm the target-specific dependency and imports do not affect other platforms.
