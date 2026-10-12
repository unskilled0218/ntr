# implemented

## changes

- Created fresh `12-task-date-metadata-layout` branches in the parent, app, and server repositories.
- Added pure local-calendar formatting, strict calendar validation, and effective due/update date selection in `app/src/lib/taskDates.ts`.
- TaskItem now shows projects, due, created, updated, and applicable done metadata in that order, separated by spaces with colon-style labels. The existing smaller metadata block provides the requested two-line layout; created remains visible alongside updated.
- List description cleanup uses the same validated effective-date map as rendering. Valid due/update tokens are hidden only when that key's effective date is displayed; malformed tokens and keys with invalid effective values remain visible. Priority, unrelated text/tags, project/context hiding, fallback, and original action objects are preserved.
- `composeEditedTask` accepts an explicit save date and emits one canonical `updated:` tag, preserving original date prefixes, contexts, and non-managed tags. Submitted tag keys override hidden old values using the backend's case-sensitive first-colon contract. An unchanged first-project selection retains all original projects; explicit selection changes preserve the existing single-select replacement behavior.
- EditTaskModal computes its local Save-attempt day inside the error-catching submit path. Opening/cancelling does not stamp; a retry computes its new date. No Task prop is optimistically mutated. Empty/updated-only edits cannot create a task from housekeeping metadata.
- An inconsistent completed task with creation but no completion is rejected before save rather than silently dropping creation or inventing completion. Genuine legacy records without dates remain supported.
- Added frontend rendering, serialization, controlled-clock edit/retry, transport/backup, TodoPane refresh, and bulk-removal preservation regressions. App-native tests cover real-file update/reload, TaskDto metadata, lifecycle/raw replacement, and failed backend writes. Server tests exercise the real Axum router, JSON/raw responses, disk reload, legacy/completed tasks, duplicate-key precedence, and actual failed atomic writes.
- Bumped app version from `0.15.13` to `0.15.14` in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration, with no dependency changes. Server changes are tests only.

## characterization and date policy

- Valid active/completed creation prefixes survived the characterized frontend payload, native store/DTO, and server HTTP/raw/reload paths. No backend production creation-date loss was reproduced, so backend production behavior was retained.
- The previous helper test explicitly expected creation to disappear for a constructed completed/creation-only shape. That regression now requires a caught validation error, with no `onSave` call or source mutation.
- Updated metadata uses the client's local calendar Save-attempt day. It is committed with a successful store write, unchanged same-day saves use the same date, and retries recompute it. Completion/reopening, label removal, backup, and raw reload/replacement preserve existing stamps rather than generating new ones.
- Known validation/storage rejections leave cached and persisted dates intact. An ambiguous connection failure after a server commit is not claimed to roll back that commit; actual persisted state must be reloaded before determining its outcome.

## verification

- Focused frontend command: `npm test -- src/labels.test.ts src/components/TaskItem.test.tsx src/components/EditTaskModal.test.tsx src/components/TodoPane.test.tsx src/api.test.ts src/lib/taskDates.test.ts` in `app`: passed, 149 tests across six files before the final additional bulk-removal case.
- Final `npm test` in `app`: passed, 393 tests across 30 files. Existing API sad-path fixtures emitted their expected disk-full/reconciliation diagnostics; all tests passed.
- `npm run build` in `app`: passed TypeScript and Vite production build.
- `TZ=Pacific/Kiritimati npm test -- src/lib/taskDates.test.ts` and `TZ=America/Los_Angeles npm test -- src/lib/taskDates.test.ts`: both passed all 16 cases, checking local-day behavior on both sides of UTC and midnight.
- `cargo test --locked` in `app/src-tauri`: passed, 44 native tests plus binary/doc targets. An initial new test used the wrong assertion type for Rust's `Option<char>` priority; that test was corrected before the passing run.
- `cargo clippy --all-targets` in `app/src-tauri`: passed without warnings.
- `cargo test --locked` in `server`: passed, 23 unit tests, 11 existing API tests, and three new task-date API/persistence tests, plus binary/doc targets.
- `cargo clippy --all-targets` in `server`: passed without warnings.
- `rustfmt --edition 2021 --check --config-path rustfmt.toml --config skip_children=true src/store.rs` in `app/src-tauri`: passed after correcting initial formatting differences in the added tests.
- `rustfmt --edition 2021 --check --config-path rustfmt.toml tests/task_dates.rs` in `server`: passed after formatting the new suite.
- `git diff --check` passed in the app/server repositories and for parent task/submodule changes. Release metadata agrees on `0.15.14`.

## runtime limits

- No X11/Wayland display was configured, and no Chromium/Chrome/Firefox, Xvfb, or WebKitWebDriver executable was available on PATH. `adb devices -l` failed because the remote daemon at `tcp:host.docker.internal:5037` refused the connection.
- Mobile/desktop visual wrapping and live browser/device edit/restart flows remain unverified. DOM tests establish the requested text/order and preserved edit state; native real-file and router tests establish persistence and transport contracts, not viewport appearance.
- No system packages or host configuration were changed. Browser/device visual checks can be completed when runtime access is available.

## release and commits

- App version: `0.15.14`.
- App commit: `127e3ec` — `Preserve task dates and render durable edit metadata`.
- Server test commit: `a3f468b` — `Test task date persistence and HTTP roundtrips`.
- App implementation and server regression tests are committed in their submodules. The parent commit records both pointers and this report.
