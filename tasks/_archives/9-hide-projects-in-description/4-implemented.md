# implemented

## changes

- Created new `9-hide-projects-in-description` branches in the parent repository and app submodule.
- Updated `TaskItem.tsx` to use the existing `bareDescription` helper with parsed projects/contexts and an empty tags map. Main task text now hides exact project/context tokens while retaining displayed tags. Added a comment explaining the list/edit distinction.
- Project metadata remains beneath the description. Existing fallback text, priority/date display, checkbox state, completed class, and original task callback payloads retain their contracts.
- Expanded `TaskItem.test.tsx` to ten cases covering multiple/repeated projects, token boundaries, emails/URLs, tag retention, label-only fallback, unlabelled tasks, and active/completed rows. Action tests check strict original-object identity and unchanged task fields against a snapshot.
- Updated existing `TodoPane.test.tsx` display assertions to the new project-free descriptions, including descending order, filtering, completion/reopening, and add/reload scenarios. Stored fixture descriptions still contain their project tokens; the filtered completed row explicitly retains project metadata.
- Bumped patch version from `0.15.11` to `0.15.12` in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration, without dependency upgrades.

## verification

- Initial focused run: TaskItem's ten tests, labels, and EditTaskModal passed. Nine TodoPane cases still expected project tokens in displayed descriptions; those assertions were updated to the requested presentation contract.
- `npm test -- src/components/TaskItem.test.tsx src/labels.test.ts src/components/EditTaskModal.test.tsx src/components/TodoPane.test.tsx` in `app`: passed, 78 tests across four files.
- `npm test` in `app`: passed, 351 tests across 29 files. Existing API error-path fixtures emit expected disk-full and reconciliation diagnostics; no tests failed.
- `npm run build` in `app`: passed TypeScript and Vite production build after the final test changes.
- `git diff --check` in the app and for parent app/task changes: passed.
- Release metadata values agree on `0.15.12`. The lockfile changes update only the app version.

## runtime limits

- Mobile/desktop visual inspection and live local/server task views were unavailable. Neither `DISPLAY` nor `WAYLAND_DISPLAY` was set, and no Chromium/Chrome/Firefox or Xvfb executable was available on PATH.
- Rendered regression tests verify text, metadata, task state, and payload preservation through the shared row; they do not establish actual viewport layout. No native compilation or device packaging was required by the plan for this frontend rendering change.

## release and commits

- Version: `0.15.12`.
- App commit: `0d57dba` — `Show task projects only in metadata`.
- App implementation is committed in the submodule. The parent commit records its pointer and this report.
