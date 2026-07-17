# Implemented

## Scope

- Add a persisted `labels.json` resource to the Tauri and HTTP backends.
- Expose label read/write operations through Tauri commands and `/api/labels`.
- Merge remembered labels with task-derived labels in the client.
- Preserve labels when the last matching task is deleted and forget them only through explicit removal.
- Move the labels resource with the configured Tauri data directory.
- Add focused Rust and TypeScript coverage for persistence, transport, merging, deletion, removal, and graceful fallback.
- Bump app and server patch versions.

## Verification

- `npm test`: 27 files, 238 tests passed.
- `npm run build`: TypeScript and Vite production build passed.
- `cargo test` in `app/src-tauri`: 42 tests passed.
- `cargo test` in `server`: 23 unit tests and 11 integration tests passed.
- `git diff --check`: passed in the app and server repositories.

## Result

Projects and contexts are stored in `labels.json`, served through both local Tauri commands and the HTTP API, and merged with labels found on tasks. Deleting the final matching task no longer removes a label or clears its active filter. The existing explicit Remove action strips the task tokens and forgets the persisted label. Server-mode writes retain the local backup behavior, older servers degrade to task-derived labels, and Tauri data-directory changes move and roll back the labels resource with the task and note files.
