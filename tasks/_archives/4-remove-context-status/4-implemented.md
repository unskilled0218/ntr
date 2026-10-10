# implemented

## changes

- Created new `4-remove-context-status` branches in the parent repository and the `app` submodule.
- Removed status and context filters, context add/edit controls, and the Contexts sort from standard and compact todo layouts.
- Task queries now apply only the project filter and include both active and completed tasks. Completion and reopening remain available.
- Removed legacy `ntr.status` preferences on todo mount. Saved Contexts sorting falls back to file order while retaining sort direction.
- Preserved the existing task and labels transport contracts, context label merging, and remembered contexts during project writes/removal.
- Added whole-token context hiding for task rows and edit descriptions. Email text, embedded `@` characters, and prefix collisions remain intact.
- Added `composeEditedTask` as the pure owner of edit serialization, preserving every context, completion state, and creation/completion dates using the existing Rust format.
- Completed-task priority pickers now show the saved effective priority, including priorities above C. Edits preserve, replace, or clear `pri:X` consistently with reopening.
- Context-only tasks show `Task without description` and allow edits to remaining fields without storing fallback text.
- Retained project creation/removal, priority, due date, other sorts, and sort direction. Updated README wording and affected comments. Existing flexible layouts required no CSS rule changes.
- Bumped app version from `0.15.6` to `0.15.7`, following the existing patch-release convention, in npm metadata, npm lockfile, Cargo metadata/lockfile, and Tauri configuration.

## verification

- `npm test` in `app`: passed, 28 files and 292 tests.
- `npm run build` in `app`: passed, including TypeScript checks and the Vite production build.
- `cargo test --locked` in `app/src-tauri`: passed, 42 native tests; binary and documentation test targets also passed.
- Added regression coverage for legacy status removal, saved-sort fallback, standard/compact control removal, project filtering with both task states, add/complete/reopen workflows, remembered context preservation, context-only tasks, exact token hiding, multiple-context edits, task switching, edit dates, and effective completed priorities.
- Added transport checks proving project-only requests omit server completion/context parameters and send null restrictions to local commands.
- Built the optional server with `cargo build --locked --manifest-path /home/dev/workdir/ntr/server/Cargo.toml --target-dir /tmp/opencode/server-target` for an isolated smoke run.
- HTTP smoke checks passed for create, list, project filtering, complete, edit, reopen, remembered-label writes, raw-file reads, and delete, using temporary data under `/tmp/opencode`.
- Passed six serializer-generated round-trips through the real local Rust task model. Cases covered retained/replaced/cleared completed priorities, priority Z, active edits, and context-only edits. Both Rust-model and HTTP results preserved expected contexts, dates, completion state, and reopened priority.
- An initial parameterized test fixture used the wrong Vitest array shape. Corrected it and reran the full frontend suite and build successfully.
- `git diff --check`: passed.
- npm, npm lockfile, Tauri, and Cargo package versions agree on `0.15.7`; locked Cargo metadata validation passed.

## runtime limitations

- Interactive Tauri/webview smoke testing was not performed. No browser automation executable was available. Standard/compact interactions were verified through React/jsdom tests; local IPC dispatch was mocked in transport tests, while native tests and serializer round-trips exercised the real local Rust model separately.
- The HTTP smoke run used the real server and serialization helper, not a graphical app connected to that server.

## release and commits

- Version: `0.15.7`.
- App commit: `4351a00` — `Remove context controls and status filtering`.
- Implementation lives in the `app` submodule. The parent commit records its updated pointer and this implementation report.
