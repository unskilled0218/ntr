# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Protected scope](#protected-scope)
- [Limits](#limits)
- [Delivery](#delivery)

## Changes

All 13 app-owned dialog templates now opt into a shared `app-modal` surface based on Settings. This covers Settings, add/edit/rename/remove, list/sort/settings pickers, compact options, HA confirmations/move recovery, task/note updates and conflicts, and open-link confirmation. Shared HA/picker templates cover their multiple user-facing variants.

Consolidated shell, backdrop, heading, form/label/input spacing, responsive bounds, action wrapping, and visible keyboard focus in `src/style.css`. Dialogs use the same white surface, 1px border, 8px radius, 1.25rem padding, 1.1rem headings, and 0.75rem content/form spacing. Nested pickers reset their base typography instead of inheriting smaller label text.

Kept specialized comparison/update widths, scrollable previews, selected/destructive states, Settings checkbox rows, and title-free remote updates. The sticky update footer shares the white surface. Only open dialogs receive flex layout; closed dialogs remain hidden. Native system dialogs are unchanged.

Added 19 modal-appearance tests and a raw-CSS-only Vitest filter so the new tests can inject the actual stylesheet without changing CSS handling in existing interaction tests. Updated parent/app README navigation, added `app/docs/modal-styling.md`, and prepared app `0.15.36` with matching version mirrors/release notes. The server stays at its existing commit/version.

## Verification

- `NODE_OPTIONS=--no-experimental-webstorage npm test`: all 789 tests across 49 files passed, including the 19 appearance checks and existing lifecycle, nested picker, HA administration/moves, retained rename/removal, Settings, and title-free preview coverage.
- `npm run build`: TypeScript and production bundling passed.
- `./scripts/release.sh --validate`: passed offline configuration/version checks without credentials/network.
- `npm run test:release`: all 52 release-tool tests passed. Publication-like output came from hermetic fixtures, not real publication.
- `/tmp/opencode/task42-check.py`: passed class-only invariance for all 13 production TSX edits, 19 maintained/task pages, 126 local links, 11 shell blocks, TOCs/anchors, protected history/vendor/native/server content, exact dependency/signing preservation, prior task records, original `todo.md`/`command.md` hashes, and whitespace.
- Appearance tests verify common shell properties, closed/open display, nested typography/field spacing, viewport/overflow policies, primary/submit/destructive/selected colors, visible-focus rules, and the shared sticky-footer surface. Existing event handlers, IDs, ARIA, and dialog content are byte-equivalent after removing only the new styling marker.

## Protected scope

No server changes or branch/version bump, native runtime changes, data/storage migrations, dependency updates, signing changes, historical release edits, task 41/archive rewrites, or edits to `todo.md`/`command.md` occurred. Rust manifest/lock/Tauri changes are only the app version mirror; release configuration changes only the notes path. Native folder choosers and platform dialogs remain system-owned.

## Limits

No real browser executable was available in PATH/cache. DOM/computed-style tests and CSS policy checks do not prove actual desktop/narrow-screen geometry, native top-layer focus, virtual-keyboard behavior, or Android rendering. No screenshots, device checks, native Rust/server suites, live HA operations, publication, deployment, merge, or push were performed. Native runtime/server logic is unchanged.

## Delivery

Work uses fresh parent/app `42-settings-modal-styling` branches and preserves the preceding task 41 work. Commit the app first, then parent README/results and app pointer. Keep server, `todo.md`, and `command.md` unstaged. No unrelated user work was discarded.
