# Implemented

- [Changes](#changes)
- [Compatibility](#compatibility)
- [Verification](#verification)
- [Known limits](#known-limits)
- [Delivery](#delivery)

## Changes

Renamed the task-grouping concept to List across app controls, filters/sorting, accessibility labels, messages, CSS/DOM identifiers, types, functions, fields, components, helper/test filenames, Rust stores/models, and maintained documentation. Rename/remove/HA management, drafts, update approval, recovery, and task content retain their existing behavior. The HA example configuration changes only a comment.

Examples: `Task.lists`, `Labels.list`, `Filter.list`, `ListRename`, `ListRemoval`, `ListManagement`, `RenameListDialog`, `HaLists`, and `HaListPicker`. Task projection operations and unrelated software-project references are deliberately unchanged.

Prepared app `0.15.35` and server `0.2.16`, including exact version mirrors, release pointers, and new notes. Dependencies, signing identity, Compose settings, and release-tool implementation are unchanged.

## Compatibility

- HTTP task JSON still emits `projects`. `listWire.ts` converts it into the frontend list domain for reads and create/update/complete/reopen responses.
- Remembered labels retain `project` in HTTP, native IPC, and `labels.json`. Rust serde mappings and frontend adapters keep this detail out of domain fields. Local label backups use the same stable key.
- The frontend still sends the legacy HTTP `project` filter for older servers. The new server also accepts `list`. Native task DTOs and filter commands use the new list names with the bundled frontend.
- Existing `ntr.sort=projects` resolves to `lists`, without rewriting storage or losing ascending/descending direction. New selections use `lists`; persistent setting keys remain unchanged.
- Raw task syntax/content, HA list/item identity, metadata schemas, default-list guards, and explicit move recovery are unchanged. Independent fixtures include literal `project planning +my-project` content to prove terminology changes do not rewrite data.
- Maintained docs use List terminology. Historical document paths/anchors remain valid through explicit anchors; archived tasks, existing release records, and vendor content are untouched.

## Verification

- Frontend: all 770 tests across 48 files passed with `NODE_OPTIONS=--no-experimental-webstorage npm test`. `npm run build` passed TypeScript and production bundling.
- App native: `cargo test --locked` passed 63 tests with one opt-in restart test initially ignored. That restart test was then explicitly run against the built loopback server and passed. `cargo clippy --locked --all-targets -- -D warnings` and rustfmt checks for changed native files passed.
- Server: `cargo test --locked` passed 84 tests (61 library, 15 API, five startup, three task-date tests). `cargo fmt --check` and `cargo clippy --locked --all-targets -- -D warnings` passed.
- Both `npm run test:task-contract` and `npm run test:ha-contract` passed against actual native/server backends and disposable loopback HTTPS/WSS fixtures. They exercise serialization, save/reload, dates, lifecycle, HA routing/admin guards, moves/recovery, and restart identities. Optional pre-removal old-server binary checks were not run because `OLD_NTR_SERVER_BIN` was unset.
- App offline release validation and all 52 release-tool tests passed. Server offline release validation, both Compose tests, 11 release-data tests, and three validation-filtered tests passed (one data test overlaps, so 15 unique server Python tests passed).
- The server consumer-settings release test still fails its hard-coded `0.2.9` assertion at `tests/test_bash_release.py:197`. An isolated archive of unchanged baseline `c81c7e9` reproduces the same failure with `0.2.15`; current metadata is `0.2.16`. The unrelated test was not weakened or edited.
- Temporary checker `/tmp/opencode/task41-check.py` passed: 33 maintained/task pages, 18 historical release pages, 232 local links, 17 shell blocks, TOCs/anchors, archived/history/vendor preservation, exact dependency/signing preservation, the original `todo.md` hash, and whitespace. Remaining old terminology is limited to compatibility boundaries/tests, historical paths/anchors, literal data fixtures, projection operations, or unrelated software-project references.

## Known limits

No live HA operations, real-device UI/install checks, release publication, deployment, push, or full server Python publication/recovery suite rerun occurred. Release-tool implementations are unchanged; their relevant local metadata/data checks were run. Fixture success does not attest deployed HA compatibility or replace desktop/Android visual and interaction checks.

## Delivery

Work uses fresh `41-rename-project-to-list` branches in parent/app/server. Component commits precede the parent README/report/submodule-pointer commit. `todo.md` remains byte-identical to its pre-task user-edited state and is not staged. No unrelated user changes were discarded.
