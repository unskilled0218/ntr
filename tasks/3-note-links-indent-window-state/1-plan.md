# 3 - Plain note links, Shift+Tab dedent, and remembered window geometry

## Goal

Add three desktop/editor conveniences to the Tauri app: Ctrl+click a plain HTTP(S) URL in the note to open it in the system browser, use Shift+Tab to remove one level of tab indentation, and restore the desktop window's last position and size after relaunch. Preserve the note editor's raw-text round trip, IME safety, Markdown-link behavior, touch gestures, undo/autosave flow, and mobile behavior.

## Current behavior

- `app/src/markdown.ts` recognizes only Markdown links in `[text](url)` form. It renders them as `a.md-link[data-href]`, and `useLinkGestures` already opens that shape on Ctrl/Cmd-click through the scheme-filtered Tauri opener. A plain URL remains ordinary text.
- `app/src/components/NotePane.tsx` inserts a literal `\t` on Tab but deliberately leaves Shift+Tab to browser focus navigation. Structural edits already flow through `paint` and `noteEdited(..., "chunk")` for caret restoration, undo, and autosave.
- `app/src-tauri/tauri.conf.json` gives the main window an initial `800x600` size. Nothing currently records move/resize events or restores window geometry.

## Plain HTTP(S) links

### `app/src/markdown.ts`

- Add bare-URL recognition inside non-code, non-Markdown-link inline segments. Accept only `http://` and `https://`; do not auto-link `javascript:`, `file:`, arbitrary schemes, or plain domain names.
- Partition bare URLs before applying emphasis so `_` and `*` in a URL remain literal and cannot be rewritten into Markdown spans. Keep the current parse order: code spans first, existing `[text](url)` links second, then bare URLs versus ordinary emphasis text.
- Render a bare URL as `<a class="md-link" data-href="...">...</a>` with no hidden duplicate text. This reuses `useLinkGestures`, `openLink`, existing link styling, Ctrl/Cmd-click desktop behavior, and touch long-press confirmation without another event path.
- Keep trailing prose punctuation outside the anchor. Strip `.`, `,`, `;`, `:`, `!`, and `?` from the detected URL tail, and strip a closing `)` or `]` only when it is unmatched within the URL; preserve balanced parentheses/brackets that are part of a URL. All stripped characters must still be emitted as ordinary text.
- Continue operating on the already HTML-escaped inline string so query separators and hostile attribute characters remain safe and decode back through `textContent`/`dataset.href`. Preserve the core invariant that rendered line text exactly equals source text.

### `app/src/markdown.test.ts`, `app/src/components/useLinkGestures.test.tsx`

- Test plain HTTP and HTTPS URLs, multiple links, query strings with `&`, underscores/asterisks, trailing punctuation, balanced/unmatched delimiters, and a line containing both Markdown and plain links.
- Verify URLs inside inline/fenced code and Markdown-link destinations are not auto-linked a second time, non-HTTP(S) schemes remain text, and every case round-trips through `readNoteText` unchanged.
- Extend the gesture probe to include a bare-link-shaped anchor and prove Ctrl/Cmd-click opens its `data-href`, while a plain click still edits and a non-link modifier-click does nothing. Keep existing touch long-press coverage because bare links inherit the same class contract.

No change is needed in `app/src/lib/openLink.ts`: it remains the second safety boundary and invokes the system browser only for allowed schemes.

## Shift+Tab dedent

### `app/src/lib/noteEdit.ts`

- Add a pure `dedentRange(text, start, end)` helper that removes at most one leading literal tab from each line touched by the caret or selection. Literal tabs are the indentation unit because forward Tab inserts `\t` and CSS renders tabs at width 2; do not silently convert or remove spaces.
- Normalize reversed/out-of-range selection endpoints. When a non-collapsed selection ends exactly at the beginning of a later line, do not dedent that unselected line.
- Return the edited text, adjusted selection start/end, and whether anything changed. Offset adjustment must account for each removed tab before or at an endpoint so the same logical content remains selected; a collapsed caret remains collapsed.

### `app/src/lib/caret.ts`

- Add a range-restoration counterpart to `setCaret` that maps logical start/end offsets back into the rendered line DOM and installs a `Range` in `window.getSelection()`. Reuse the same line/text-node walking rules as `setCaret` so highlighting spans and empty lines preserve the line invariant.
- Keep `setCaret` as the collapsed convenience path, delegating to the shared boundary logic rather than duplicating traversal.

### `app/src/components/NotePane.tsx`

- Handle unmodified Shift+Tab inside the existing non-composing keydown path before forward Tab. Always call `preventDefault` so Shift+Tab belongs to the editor and never unexpectedly moves focus, including when no touched line can be dedented.
- Read the logical selection with `getCaretRange`, apply `dedentRange`, and only when text changed repaint the note, restore the adjusted selection, mark the active edit line, and call `noteEdited(..., "chunk")`. A no-op must not create history or schedule autosave.
- Leave all Ctrl/Meta/Alt shortcuts and composing key events untouched; IMEs continue to receive Shift+Tab if the native event is composing.

### `app/src/lib/noteEdit.test.ts`, `app/src/lib/caret.test.ts`, `app/src/components/NotePane.test.tsx`

- Cover a collapsed caret on first/middle/last lines, indented and unindented lines, reversed/clamped ranges, multi-line selections, and a selection ending at the next line's offset zero.
- Verify range restoration across plain text, highlighted spans, empty lines, and a backward logical selection if the browser test environment supports direction; at minimum assert the normalized selected text and offsets.
- Replace the current expectation that Shift+Tab is left for focus navigation. Assert it is prevented, removes one leading tab per touched line, preserves the selection/caret, creates one undo chunk, autosaves the new text, and no-ops without saving/history when no leading tab exists. Retain composing-key coverage.

## Remember window position and size

### `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`

- Add a desktop-only `tauri-plugin-window-state` dependency compatible with the currently resolved Tauri `2.11.x` line. Pin to the compatible `2.4.x` plugin line rather than allowing `2.5.x` to force an unrelated Tauri `2.12` framework upgrade; regenerate the lockfile normally.
- Keep the dependency out of Android/iOS builds with a desktop target dependency section. No JavaScript package or capability permission is needed because persistence and restoration stay in Rust.

### `app/src-tauri/src/lib.rs`

- On desktop builds, register `tauri_plugin_window_state::Builder` on the existing Tauri builder with exactly `StateFlags::POSITION | StateFlags::SIZE` before `run`.
- Do not enable maximized, fullscreen, visible, or decoration flags: the request is only for the last normal position and dimensions. Keep the configured `800x600` geometry as the first-run/no-valid-state fallback.
- Leave mobile startup unchanged. The plugin owns event tracking, app-data persistence, startup restoration, and monitor-aware window placement; do not add a parallel localStorage implementation or frontend move/resize listeners.

### Runtime checks

- Confirm the plugin state file is created in the Tauri app-data directory after moving/resizing and closing the app, and that a relaunch restores both values.
- Verify a maximized/fullscreen close does not make maximized/fullscreen state sticky, and normal geometry remains usable after returning to normal mode.
- Test a saved window from a secondary monitor after that monitor is disconnected or its scale/resolution changes; the restored window must remain reachable. If the plugin version does not clamp stale geometry, add a focused native restore guard rather than frontend persistence.

## Version

Bump the app patch version from `0.15.5` to `0.15.6` consistently in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`.

## Out of scope

Auto-linking domains without a scheme, non-HTTP(S) protocols, changing the explicit Markdown-link syntax/reveal behavior, opening links on an unmodified click, space-based indentation, block indentation with Tab, remembering maximized/fullscreen/visibility state, synchronizing window geometry between devices, and server changes.

## Verification

- Run focused tests with `npx vitest run src/markdown.test.ts src/components/useLinkGestures.test.tsx src/lib/noteEdit.test.ts src/lib/caret.test.ts src/components/NotePane.test.tsx`.
- Run `npm test` and `npm run build` in `app/`.
- Run `cargo fmt --check`, `cargo check`, and `cargo test` in `app/src-tauri/`; if repository-wide formatting still reports only the known untouched baseline files, verify each changed Rust file directly and record the limitation.
- Run the Tauri desktop app and verify Ctrl/Cmd-click for plain and Markdown links, plain-click caret placement, touch long-press confirmation, URL punctuation boundaries, Shift+Tab for one and several selected lines, undo/autosave after dedent, and IME bypass.
- Move and resize the desktop window, close/reopen it, and repeat across maximize/restore and monitor/DPI changes. Build or check Android to confirm the desktop-only plugin does not enter the mobile dependency graph or startup path.
