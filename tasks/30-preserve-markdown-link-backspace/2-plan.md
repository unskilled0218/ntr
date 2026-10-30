# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [Summary](#summary)
  - [1. Protect logical line joins](#1-protect-logical-line-joins)
  - [2. Test text, caret, and persistence](#2-test-text-caret-and-persistence)
  - [3. Verify platforms and document the change](#3-verify-platforms-and-document-the-change)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Fix Backspace at the start of a note line so joining it to the preceding line preserves that line's complete Markdown link and places the caret at the join. Preserve the rest of the note editor's editing, selection, undo, autosave, composition, and link behavior. Do not change the server or unrelated task behavior.

## Implementation Plan

### Summary

`app/src/markdown.ts` renders the complete raw link as nested spans, while `app/src/style.css` hides its syntax outside the active line. `app/src/components/NotePane.tsx` lets the browser perform Backspace and then reads the mutated DOM on `input`. A WebView may therefore remove hidden link syntax during a native line join. This is a plausible mechanism, not a device-confirmed root cause. `app/src/lib/caret.ts` already represents note text and selection as offsets with one newline between direct-child lines. Use those logical offsets to perform the affected join before native deletion can alter the rendered link.

### 1. Protect logical line joins

- Inspect actual `keydown` and `beforeinput` events and selection boundaries on an available affected WebView first. Characterize the example `[example](https://exmaple.com)\n` with the caret on the empty second line, including whether the mobile keyboard emits a cancelable `deleteContentBackward` event without a useful keydown. Report unavailable environments rather than assuming their behavior.
- Add a small logical-text join operation, preferably in `app/src/lib/noteEdit.ts`, that applies only when a valid collapsed editor selection is immediately after a newline. Delete exactly that newline, retain every other character, and return the join offset as the caret. Handle a nonempty following line as well as a blank line. Use the logical newline rather than parsing or special-casing URLs; ordinary line joins gain the same deterministic behavior.
- Integrate the operation into `NotePane.tsx` before the browser edits the DOM. Handle cancelable `beforeinput` with `inputType === "deleteContentBackward"` so mobile deletion is covered, and use a narrowly scoped unmodified Backspace keydown fallback where necessary. If using a native listener, install it once and remove it on unmount. Prevent default only when the join is actually handled and the event is cancelable. Ensure a keydown handled by the fallback cannot also apply a later `beforeinput` join. Do not silently claim protection when the platform supplies only noncancelable events; investigate and report that limitation.
- Define event ownership explicitly: record a modified Backspace keydown, including Shift, Ctrl, Alt, or Meta, and let its subsequent backward-deletion `beforeinput` events pass through without invoking the join, even if their input type is `deleteContentBackward`. Retain this exclusion through repeated modified keydowns and associated input events; clear it on Backspace keyup, editor blur, composition start, unmount, or a fresh unmodified Backspace keydown. Do not prevent the modified keydown or its native input. A mobile `beforeinput` with no active modified-key sequence must still take the normal join path. If platform event ordering makes provenance ambiguous, prefer leaving that event native and report the limitation instead of claiming shortcut preservation.
- Obtain a valid editor selection and check it is collapsed before preventing default. Do not intercept selection deletion, document-start Backspace, mid-line Backspace, modified Backspace, forward Delete, or unrelated input types. Leave IME composition and native composing key events untouched, including `beforeinput` during composition. Do not infer a caret from the end of the text when selection is unavailable.
- Apply the join through the editor's `paint` and `noteEdited` paths exactly once, with a structural `chunk` history entry. Update the paint/caret path as needed so it renders the text, marks the destination line `.md-edit` using the intended logical caret offset, and only then places the selection. Do not first rely on a selection inside `display: none` link syntax to identify the line. Preserve behavior for unfocused renders and noncollapsed selection restoration, and keep the one-line reveal invariant. Preserve revision tracking, save debounce, remote-update and destination guards. Do not manually call the browser's input path or write directly to storage; leave link gestures unchanged.
- Verify the selection-to-offset mapping at the beginning of an empty `<div><br></div>` and nonempty line, including element boundary points. If current caret helpers misreport a real boundary, fix that mapping for direct child lines without changing the raw Markdown/one-newline invariant or selections outside the editor.

### 2. Test text, caret, and persistence

- Add focused pure tests for the logical join: link immediately before an empty or nonempty line, multiple links, trailing text, plain text, multiple blank lines, and start-of-document/no-newline cases. Verify the exact resulting text and logical caret offset.
- Extend `app/src/components/NotePane.test.tsx` with the reported link and a focused empty second line. Dispatch the supported cancelable deletion event, assert only the newline is removed, `readNoteText` returns the full raw link, the selection is collapsed immediately after `)`, and the active line reveals link syntax. Repeat with text on the next line and with a browser-style element boundary selection rather than only helper-generated selections.
- Verify one history entry and a single debounced save containing the intact link; undo must restore the original line break and original content. Check that repeated boundary deletion removes at most one newline per input and that keydown plus beforeinput cannot double-apply the operation. Exercise the desktop fallback and mobile-style beforeinput-only sequence separately.
- Test complete modified-key sequences rather than keydown alone: modified Backspace followed by cancelable `deleteContentBackward` must leave both events unprevented and must not run the logical join. Cover repeats and different input types, Backspace keyup, blur, composition start, and a subsequent unmodified keydown or mobile beforeinput-only deletion; verify the exclusion neither leaks nor consumes the next unrelated operation. Test modifier-key release ordering and document any platform-specific ambiguity.
- Test that the destination line is revealed before selection restoration, including links ending the line and links followed by text, without changing other lines or unfocused rendering. Verify subsequent typing lands after the intact link. Run the same caret and next-character check in a real WebView when available; a jsdom selection assertion alone cannot establish hidden-node behavior.
- Check that noncollapsed selections, mid-line and document-start Backspace, modifier keys, forward deletion, unrelated input types, missing/outside selection, noncancelable events, and composing input are not intercepted or unexpectedly saved. Keep existing IME, caret, paste, undo, link and autosave suites passing. Restore any global listeners, selection, fake timers, and mocks after tests.
- jsdom does not execute real contenteditable default deletion or CSS visibility behavior. Unit and component tests must assert the controlled path and event handling, not claim proof of the original WebView bug or noncancelable native behavior.

### 3. Verify platforms and document the change

- Run `npm test` and `npm run build` in `app/`; run `cargo test -j 1` and `cargo clippy --all-targets -j 1` in `app/src-tauri/` if available. Do not install system packages; record missing prerequisites and any skipped checks.
- On available desktop WebViews and Android, reproduce the original scenario before the fix and verify after it using a real keyboard or mobile keyboard as appropriate. Verify empty and populated next lines, caret position, next typing, undo, save/reload, ordinary Backspace, selection deletion, IME, and link opening. Record platform, input method, results, and any unavailable device or noncancelable-event limitation.
- Update `app/README.md` and relevant `app/docs/features.md` or a dedicated existing note-editing document concisely, keeping their tables of contents valid. Record implementation and verification in `4-implemented.md`.
- Follow the existing patch-release convention: update the client from `0.15.25` to `0.15.26` across npm, Cargo, lockfiles, and Tauri configuration if no intervening version change occurs. Commit client changes in the app submodule and update the parent gitlink; do not touch unrelated `todo.md` changes.

## Acceptance Criteria

- Backspace at the start of the next line joins `[example](https://exmaple.com)\n` into `[example](https://exmaple.com)` with the caret immediately after the closing `)`, without deleting link syntax.
- A populated next line is appended intact, with the caret at the join; a single action removes exactly one newline.
- One undo restores the pre-join text, and autosave writes the intact joined text through the existing guarded save path.
- Unrelated deletions, selections, modifier shortcuts, IME composition, link interactions, and ordinary editing retain their existing behavior.
- Relevant automated checks pass. Desktop and Android real-input validation, missing toolchains, and any unsupported noncancelable input path are reported separately.

## Risks And Decisions

- Preventing default only after a valid logical join avoids changing browser behavior for other deletions, including selections and IME preedit.
- A collapsed selection can be represented by different DOM boundary points. Tests must check actual browser representations as well as synthetic offsets; jsdom cannot establish native caret placement.
- `beforeinput` support and cancelability differ by WebView and input method. A keydown fallback does not by itself cover Android virtual keyboards; verify both routes and avoid duplicate edits.
- Android or desktop hardware may be unavailable. An unverified platform remains a limitation, not evidence that the bug is fixed there.
